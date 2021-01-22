import Pkg
Pkg.add("DelimitedFiles")
Pkg.add("ProgressMeter")
Pkg.add("PyPlot")

using DelimitedFiles, ProgressMeter, PyPlot

include("./util.jl")
include("./parsers.jl")
include("./Algorithms/TEAVAR.jl")
include("./simulation.jl")


function probabilityNoise(topologies,
                          demand_downscales,
                          num_demands,
                          iterations,
                          cutoff,
                          noise; paths="SMORE",
                          weibull_scale=.0001,
                          add_noise="SCENARIOS",
                          plot=true,
                          dirname="./data/raw/probability_noise")
    env = Gurobi.Env()

    error_vals = [[] for i in 1:length(noise)]

    dir = nextRun(dirname)
    for j in 1:length(noise)
        writedlm("$(dir)/noise_$(noise[j])_error", [["val_optimal", "val", "error_val"]])
    end

    progress = ProgressMeter.Progress(length(topologies)*num_demands*iterations*length(noise), .1, "Computing Probability Noise Error...", 50)
    noise_error = zeros(length(noise))
    for t in 1:length(topologies)
        links, capacity, link_probs, nodes = readTopology(topologies[t])
        for d in 1:num_demands
            demand, flows = readDemand("$(topologies[t])/demand", length(nodes), d, downscale=demand_downscales[t])
            # T, Tf, k = parsePaths("$(topologies[t])/paths/$(paths)", links, flows)
            k = 10
            T, Tf, g = getTunnels(nodes, links, capacity, flows, k)

            for i in 1:iterations
                weibull_probs = weibullProbs(length(link_probs), shape=.8, scale=weibull_scale)
                scenarios, scenario_probs = subScenarios(weibull_probs, cutoff, first=true, last=false)
                # scenarios_w_noise, scenario_probs_w_noise = subScenarios(weibull_probs_noise, cutoff, first=true, last=false)
                var, cvar, a, max_u = TEAVAR(env, links, capacity, flows, demand, 0, k, T, Tf, scenarios, scenario_probs)
                losses = calculateLossReallocation(links, capacity, demand, flows, T, Tf, k, a, scenarios, scenario_probs)
                val_optimal = sum(losses .* scenario_probs)
                # val_optimal = 1-cvar
                # val_optimal = sum((1 .- max_u) .* scenario_probs)
                for j in 1:length(noise)
                    scenario_probs_noise = []
                    if add_noise == "EVENTS"
                        weibull_probs_noise = map(p -> p + (p * noise[j] * rand(Uniform(-1, 1))), weibull_probs)
                        scenario_probs_noise = getProbabilities(scenarios, weibull_probs_noise)
                        scenario_probs_noise = scenario_probs_noise ./ sum(scenario_probs_noise)
                    else
                        scenario_probs_noise = map(p -> p + (p * noise[j] * rand(Uniform(-1, 1))), scenario_probs)
                        scenario_probs_noise = scenario_probs_noise ./ sum(scenario_probs_noise)
                    end
                    println(scenario_probs_noise)
                    # var, cvar, a, max_u = TEAVAR(env, links, capacity, flows, demand, 0, k, T, Tf, scenarios, scenario_probs_noise)
                    losses = calculateLossReallocation(links, capacity, demand, flows, T, Tf, k, a, scenarios, scenario_probs_noise)
                    val = sum(losses .* scenario_probs_noise)
                    # val = 1-cvar
                    # val = sum((1 .- max_u) .* scenario_probs_noise)
                    err = abs((val_optimal - val)/val_optimal)
                    noise_error[j] += err
                    open("$(dir)/noise_$(noise[j])_error", "a") do io
                        writedlm(io, transpose([val_optimal, val, err]))
                    end
                    ProgressMeter.next!(progress, showvalues = [(:topology,topologies[t]), (:demand,"$(d)/$(num_demands)"), (:iterations,"$(i)/$(iterations)"), (:noise, noise[j]), (:error, err)])
                end
            end
        end
    end
    y_vals = noise_error ./ (num_demands * iterations * length(topologies))

    # LOG RESULTS
    writedlm("$(dir)/noises", noise)
    writedlm("$(dir)/y_vals", y_vals)
    writedlm("$(dir)/params", [["topologies", "demand_downscales", "num_demands", "iterations", "cutoff", "noise", "paths", "weibull_scale"], [topologies, demand_downscales, num_demands, iterations, cutoff, noise, paths, weibull_scale]])

    # PLOT
    if plot
        PyPlot.clf()
        nbars = length(noise)
        barWidth = 1/(nbars)
        for i in 1:length(y_vals)
            PyPlot.bar(barWidth .* i, y_vals[i], alpha=0.8, width=barWidth)
        end
        PyPlot.ylabel("Percent Error", fontweight="bold")
        PyPlot.legend(noise, loc="upper right")
        PyPlot.savefig("$(dir)/plot.png")
        PyPlot.show()
    end
end

# probabilityNoise(["./data/B4", "./data/IBM"], [2000, 1000], [false, false], 2, 20, .0001, [.00001,.0001, .001, .01, .05, .1, .15, .2], paths="SMORE", weibull_scale=.0002)
# probabilityNoise(["B4"], [2000], 2, 100, .00001, [.01, .05, .1, .15, .2], paths="SMORE", weibull_scale=.001, add_noise="EVENTS")
