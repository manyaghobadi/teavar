import Pkg
Pkg.add("DelimitedFiles")
Pkg.add("ProgressMeter")
Pkg.add("PyPlot")

using DelimitedFiles, ProgressMeter, PyPlot

include("./util.jl")
include("./parsers.jl")
include("./Algorithms/TEAVAR.jl")
include("./Algorithms/MaxMin.jl")
include("./Algorithms/SMORE.jl")
include("./Algorithms/FFC.jl")
include("./simulation.jl")

function getThroughputGraphs(algorithmns,
                              topologies,
                              demand_downscales,
                              num_demands,
                              iterations,
                              bars,
                              cutoff;
                              k=12,
                              teavar_paths="KSP",
                              weibull_scale=.0001,
                              plot=true,
                              dirname="./data/raw/throughput_data/")
    env = Gurobi.Env()
    x_vals = bars
    y_vals_vars = []
    y_vals_cvars = []
    labels = []


    ## COMPUTE SCENARIOS
    scenarios_all = []
    scenario_probs_all = []
    for t in 1:length(topologies)
        topology = topologies[t]
        links, capacity, link_probs, nodes = readTopology(topology, downscale=demand_downscales[t])
        scenarios_all_top = []
        scenario_probs_top = []
        for i in 1:iterations
            link_probs = weibullProbs(length(links), shape=.8, scale=weibull_scale)
            scenarios, probs = subScenarios(link_probs, cutoff, first=true, last=false)
            push!(scenarios_all_top, scenarios)
            push!(scenario_probs_top, probs)
        end
        push!(scenarios_all, scenarios_all_top)
        push!(scenario_probs_all, scenario_probs_top)
    end
    
    progress = ProgressMeter.Progress(length(algorithmns)*length(topologies)*num_demands*iterations*length(x_vals), .1, "Computing Throughput...", 50)
    for alg in 1:length(algorithmns)
        beta_cvar_totals = zeros(length(x_vals))
        beta_var_totals = zeros(length(x_vals))
        for t in 1:length(topologies)
            links, capacity, link_probs, nodes = readTopology(topologies[t])
            for d in 1:num_demands
                demand, flows = readDemand("$(topologies[t])/demand", length(nodes), d, downscale=demand_downscales[t])
                for i in 1:iterations
                    if algorithmns[alg] == "TEAVAR"
                        if teavar_paths != "KSP"
                            T, Tf, k = parsePaths("$(topologies[t])/paths/$(teavar_paths)", links, flows)
                        else
                            T, Tf, g = getTunnels(nodes, links, capacity, flows, k)
                        end
                        for b in 1:length(x_vals)
                            beta = x_vals[b]
                            var, cvar, a = TEAVAR(env, links, capacity, flows, demand, beta, k, T, Tf, scenarios_all[t][i], scenario_probs_all[t][i], average=true)
                            losses = calculateLossReallocation(links, capacity, demand, flows, T, Tf, k, a, scenarios_all[t][i], scenario_probs_all[t][i])
                            cvar = CVAR(losses, scenario_probs_all[t][i], beta)
                            var = VAR(losses, scenario_probs_all[t][i], beta)
                            beta_cvar_totals[b] += cvar
                            beta_var_totals[b] += var
                            ProgressMeter.next!(progress, showvalues = [(:algorithmn,algorithmns[alg]), (:topology,topologies[t]), (:demand,"$(d)/$(num_demands)"), (:iteration, "$(i)/$(iterations)"), (:beta, x_vals[b]), (:cvar, cvar), (:var, var)])
                        end
                    else
                        T, Tf, k = parsePaths("$(topologies[t])/paths/$(algorithmns[alg])", links, flows)
                        a = parseYatesSplittingRatios("$(topologies[t])/paths/$(algorithmns[alg])", k, flows)
                        losses = calculateLossReallocation(links, capacity, demand, flows, T, Tf, k, a, scenarios_all[t][i], scenario_probs_all[t][i])
                        for b in 1:length(x_vals)
                            beta = x_vals[b]
                            cvar = CVAR(losses, scenario_probs_all[t][i], beta)
                            var = VAR(losses, scenario_probs_all[t][i], beta)
                            beta_cvar_totals[b] += cvar
                            beta_var_totals[b] += var
                            ProgressMeter.next!(progress, showvalues = [(:algorithmn,algorithmns[alg]), (:topology,topologies[t]), (:demand,"$(d)/$(num_demands)"), (:iteration, "$(i)/$(iterations)"), (:beta, x_vals[b]), (:cvar, cvar), (:var, var)])
                        end
                    end
                end
            end
        end
        beta_avg_vars = beta_var_totals ./ (num_demands * length(topologies) * iterations * length(x_vals))
        beta_avg_cvars = beta_cvar_totals ./ (num_demands * length(topologies) * iterations * length(x_vals))
        push!(y_vals_vars, 1 .- beta_avg_vars)
        push!(y_vals_cvars, 1 .- beta_avg_cvars)
        push!(labels, algorithmns[alg])
    end


    # LOG OUTPUTS
    dir = nextRun(dirname)
    writedlm("$(dir)/x_vals", x_vals)
    writedlm("$(dir)/y_vals_cvars", y_vals_cvars)
    writedlm("$(dir)/y_vals_vars", y_vals_vars)
    writedlm("$(dir)/params", [["algorithmns", "topologies", "demand_downscales", "num_demands", "iterations", "bars", "cutoff", "k", "tevar_paths", "weibull_scale"], [algorithmns, topologies, demand_downscales, num_demands, iterations, bars, cutoff, k, teavar_paths, weibull_scale]])


    if plot
        PyPlot.clf()
        nbars = length(labels)
        ngroups = length(x_vals)
        barWidth = 1/(nbars + 1)
        for bar in 1:nbars
            group_ys = map(tup -> y_vals_vars[bar][tup[1]], enumerate(x_vals))
            PyPlot.bar(collect(1:ngroups) .- 1 .+ (barWidth .* bar), group_ys, alpha=0.8, width=barWidth)
        end
        PyPlot.xlabel("Probability", fontweight="bold")
        PyPlot.ylabel("P(T > X)", fontweight="bold")
        PyPlot.legend(labels, loc="lower right")
        PyPlot.xticks(collect(1:ngroups) .- 1 .+ (barWidth * (nbars+1)/2), bars)
        PyPlot.savefig("$(dir)/plot.png")
        PyPlot.show()
    end
end

# getBarGraphsMultiple(["SMORE", "FFC", "ECMP"],
#                      ["./data/B4", "./data/IBM"],
#                      [10000, 5000],
#                      10,
#                      10,
#                      [.9, .95, .99, .999, .9999],
#                      .0005,
#                      tevar_paths="SMORE",
#                      weibull_scale=.01)
