import Pkg
Pkg.add("DelimitedFiles")
Pkg.add("ProgressMeter")
Pkg.add("PyPlot")
Pkg.add("Gurobi")

using DelimitedFiles, ProgressMeter, PyPlot, Gurobi

include("./util.jl")
include("./parsers.jl")
include("./Algorithms/TEAVAR.jl")
include("./Algorithms/MaxMin.jl")
include("./Algorithms/SMORE.jl")
include("./Algorithms/FFC.jl")
include("./simulation.jl")

function availabilityPlot(
    algorithmns,
    topologies,
    demand_downscales,
    num_demands,
    iterations,
    cutoff,
    start,
    step,
    finish;
    k = 12,
    target = 0,
    xliml = 0.95,
    xlimr = 1.0001,
    paths = "KSP",
    weibull_scale = 0.0001,
    plot = true,
    dirname = "./data/raw/availability/",
)
    env = Gurobi.Env()
    availability_vals = [[] for i = 1:length(algorithmns)]

    dir = nextRun(dirname)
    for algorithmn in algorithmns
        mkdir("$(dir)/$(algorithmn)")
    end

    scenarios_all = []
    scenario_probs_all = []
    for t = 1:length(topologies)
        topology = topologies[t]
        links, capacity, link_probs, nodes = readTopology(topology)
        scenarios_all_top = []
        scenario_probs_top = []
        for i = 1:iterations
            link_probs = weibullProbs(length(links), shape = 0.8, scale = weibull_scale)
            scenarios, probs = subScenarios(link_probs, cutoff, first = true, last = false)
            push!(scenarios_all_top, scenarios)
            push!(scenario_probs_top, probs)
            println(probs)
        end
        push!(scenarios_all, scenarios_all_top)
        push!(scenario_probs_all, scenario_probs_top)
    end

    scales = collect(start:step:finish)
    progress = ProgressMeter.Progress(
        length(scales) *
        length(topologies) *
        num_demands *
        iterations *
        length(algorithmns),
        0.1,
        "Computing Availability...",
        50,
    )
    confidence = zeros(length(scales), 3 * length(algorithmns) + 1)
    confidence[:, 1] = scales
    for s = 1:length(scales)
        availabilities = [[] for i = 1:length(algorithmns)]
        for t = 1:length(topologies)
            links, capacity, link_probs, nodes = readTopology(topologies[t])
            for d = 1:num_demands
                demand, flows = readDemand(
                    "$(topologies[t])/demand",
                    length(nodes),
                    d,
                    scale = scales[s],
                    downscale = demand_downscales[t],
                )
                if paths != "KSP"
                    T, Tf, k = parsePaths("$(topologies[t])/paths/$(paths)", links, flows)
                else
                    T, Tf, g = getTunnels(nodes, links, capacity, flows, k)
                end
                for i = 1:iterations
                    for alg = 1:length(algorithmns)
                        if algorithmns[alg] == "TEAVAR"
                            var, cvar, a = TEAVAR(
                                env,
                                links,
                                capacity,
                                flows,
                                demand,
                                scenario_probs_all[t][i][1] - 0.01,
                                k,
                                T,
                                Tf,
                                scenarios_all[t][i],
                                scenario_probs_all[t][i],
                                average = true,
                            )
                        elseif algorithmns[alg] == "ECMP"
                            a = ones(size(Tf, 1), k)
                        elseif algorithmns[alg] == "MaxMin"
                            a = MaxMin(env, links, capacity, flows, demand, k, T, Tf)
                        elseif algorithmns[alg] == "FFC-1"
                            a, _ = FFC(env, links, capacity, flows, demand, 1, T, Tf)
                        elseif algorithmns[alg] == "FFC-2"
                            a, _ = FFC(env, links, capacity, flows, demand, 2, T, Tf)
                        elseif algorithmns[alg] == "SMORE"
                            a = SMORE(env, links, capacity, flows, demand, T, Tf)
                        else
                            T, Tf, k = parsePaths(
                                "$(topologies[t])/paths/$(algorithmns[alg])",
                                links,
                                flows,
                            )
                            a = parseYatesSplittingRatios(
                                "$(topologies[t])/paths/$(algorithmns[alg])",
                                k,
                                flows,
                            )
                        end
                        losses = calculateLossReallocation(
                            links,
                            capacity,
                            demand,
                            flows,
                            T,
                            Tf,
                            k,
                            a,
                            scenarios_all[t][i],
                            scenario_probs_all[t][i],
                        )
                        println(losses)
                        open(
                            "$(dir)/$(algorithmns[alg])/$(algorithmns[alg])_losses.txt",
                            "a",
                        ) do io
                            writedlm(io, transpose(hcat(scenario_probs_all[t][i], losses)))
                        end
                        availability = PDF(losses, scenario_probs_all[t][i], target)
                        println(availability)
                        push!(availabilities[alg], availability)
                        ProgressMeter.next!(
                            progress,
                            showvalues = [
                                (:topology, topologies[t]),
                                (:scale, scales[s]),
                                (:demand, "$(d)/$(num_demands)"),
                                (:iteration, "$(i)/$(iterations)"),
                                (:algorithmn, algorithmns[alg]),
                                (:availability, availability),
                            ],
                        )
                    end
                end
            end
        end

        for alg = 1:length(algorithmns)
            confidence[s, (alg-1)*3+2] =
                sum(availabilities[alg]) / (num_demands * iterations * length(topologies))
            confidence[s, (alg-1)*3+3] = minimum(availabilities[alg])
            confidence[s, (alg-1)*3+4] = maximum(availabilities[alg])
            open(
                "$(dir)/$(algorithmns[alg])/$(algorithmns[alg])_availabilities.txt",
                "a",
            ) do io
                writedlm(io, transpose(availabilities[alg]))
            end
            push!(
                availability_vals[alg],
                sum(availabilities[alg]) / (num_demands * iterations * length(topologies)),
            )
        end
    end

    # write to output directory
    writedlm("$(dir)/availabilities", availability_vals)
    writedlm("$(dir)/scales", scales)
    if paths == nothing
        paths = ""
    end
    writedlm(
        "$(dir)/params",
        [
            [
                "algorithmns",
                "topologies",
                "demand_downscales",
                "num_demands",
                "iterations",
                "cutoff",
                "scales",
                "k",
                "target",
                "paths",
                "weibull_scale",
            ],
            [
                algorithmns,
                topologies,
                demand_downscales,
                num_demands,
                iterations,
                cutoff,
                scales,
                k,
                target,
                paths,
                weibull_scale,
            ],
        ],
    )
    writedlm("$(dir)/confidence", confidence)

    if plot
        PyPlot.clf()
        for i = 1:size(availability_vals, 1)
            PyPlot.plot(availability_vals[i], scales)
        end
        PyPlot.xlabel("Availability", fontweight = "bold")
        PyPlot.ylabel("Demand Scale", fontweight = "bold")
        PyPlot.xlim(left = xliml, right = xlimr)
        PyPlot.legend(algorithmns, loc = "upper right")
        PyPlot.savefig("$(dir)/plot.png")
        PyPlot.show()
    end
end

# availabilityPlot(["TEAVAR", "SMORE", "ECMP", "FFC", "MaxMin"], ["./data/B4"], [10000], 10, 10, .0001, 1, .1, 3.5, weibull_scale=.001, paths="SMORE")
# availabilityPlot(["TEAVAR", "SMORE_ED", "ECMP", "FFC_ED"], ["./data/IBM"], [4500], [false], 4, 4, .001, collect(1:.1:3.5), weibull_scale=.001, paths="FFC_ED")
# availabilityPlot(["TEAVAR", "SMORE_ED", "ECMP", "FFC_ED", "MaxMin"], ["./data/IBM"], [4500], [false], 4, 4, .0005, collect(1:.1:3.5), weibull_scale=.001, paths="FFC_ED")
# availabilityPlot(["TEAVAR", "SMORE2", "ECMP", "FFC-1", "FFC-2", "MaxMin"], ["./data/IBM"], [2000000], [false], 3, 3, .0001, collect(1:.1:4), weibull_scale=.0004)
# availabilityPlot(["TEAVAR", "SMORE2", "ECMP", "FFC-1", "FFC-2", "MaxMin"], ["./data/B4"], [2000000], [false], 4,4, .00001, collect(1:.1:4), weibull_scale=.0005)

# availabilityPlot(["TEAVAR", "SMORE2", "ECMP", "FFC-1", "FFC-2", "MaxMin"], ["./data/ATT"], [5000], [true], 2, 2, .0001, collect(1:.1:3.5), weibull_scale=.0002, paths=nothing, k=8)
# availabilityPlot(["TEAVAR", "SMORE_ED", "ECMP", "FFC_ED", "MaxMin"], ["./data/ATT"], [5000], [true], 2, 4, .001, collect(1:.2:3.5), weibull_scale=.001, paths="FFC_ED")
# availabilityPlot(["FFC-2"], ["./data/XNet"], [500], [true], 4, 2, .0001, collect(3:.05:3.25), weibull_scale=.0001, paths="SMORE")
# availabilityPlot(["TEAVAR", "SMORE2", "ECMP", "FFC-1", "FFC-2", "MaxMin"], ["./data/XNet"], [1000], 3, 1, .00001, collect(1:.1:6.4), weibull_scale=.0005, paths=nothing, k=8)
