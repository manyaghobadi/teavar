using DelimitedFiles, ProgressMeter, PyPlot

include("./util.jl")
include("./parsers.jl")
include("./Algorithms/TEAVAR.jl")
include("./simulation.jl")

function pathSelection(topologies,
                      demand_downscales,
                      paths,
                      num_demands,
                      bars,
                      cutoff;
                      scale=1.0,
                      ksp=[],
                      weibull=true,
                      plot=true,
                      dirname="./data/raw/path_selection")
                      
    env = Gurobi.Env()
    x_vals = bars
    y_vals = []
    labels = []
    scenarios = []
    probs = []

    # COMPUTE SCENARIOS
    for i in 1:length(topologies)
        links, capacity, link_probs, nodes = readTopology(topologies[i])
        if weibull == true
            weibull_probs = weibullProbs(length(link_probs), shape=.8, scale=.0001)
            temp_s, temp_p = subScenarios(weibull_probs, (sum(weibull_probs)/length(weibull_probs))^2, first=true, last=false)
            push!(scenarios, temp_s)
            push!(probs, temp_p)
        else
            scenario, prob = subScenarios(link_probs, cutoff, first=false, last=false)
            push!(scenarios, scenario)
            push!(probs, prob)
        end
    end


    for p in 1:length(paths)
        all_var_vals = [[] for i=1:length(x_vals)]
        algorithmn_vals = []
        progress = ProgressMeter.Progress(length(topologies)*num_demands*length(x_vals), .1, "Computing TEAVAR_$(paths[p])...", 50)
        for i in 1:length(topologies)
            links, capacity, link_probs, nodes = readTopology(topologies[i])
            for d in 1:num_demands
                demand, flows = readDemand("$(topologies[i])/demand", length(nodes), d, scale=scale, downscale=demand_downscales[i])
                T, Tf, k = parsePaths("$(topologies[i])/paths/$(paths[p])", links, flows)
                vals = map(b -> (ProgressMeter.next!(progress, showvalues = [(:topology,topologies[i]), (:demand,"$(d)/$(num_demands)"), (:paths,paths[p])]);
                                 TEAVAR(env, links, capacity, flows, demand, b, k, T, Tf, scenarios[i], probs[i])), x_vals)
                for j in 1:length(vals)
                    push!(all_var_vals[j], vals[j][2])
                end
            end
        end
        for j in 1:length(all_var_vals)
            push!(algorithmn_vals, sum(all_var_vals[j])/length(all_var_vals[j]))
        end
        push!(y_vals, algorithmn_vals)
        push!(labels, "Teavar_$(paths[p])")
    end

    for p in 1:length(ksp)
        all_var_vals = [[] for i=1:length(x_vals)]
        algorithmn_vals = []
        progress = ProgressMeter.Progress(length(topologies)*num_demands*length(x_vals), .1, "Computing TEAVAR_ksp$(ksp[p])...", 50)
        for i in 1:length(topologies)
            links, capacity, link_probs, nodes = readTopology(topologies[i])
            for d in 1:num_demands
                demand, flows = readDemand("$(topologies[i])/demand", length(nodes), d, scale=scale, downscale=demand_downscales[i])
                T, Tf, g = getTunnels(nodes, links, capacity, flows, ksp[p])
                vals = map(b -> (ProgressMeter.next!(progress, showvalues = [(:topology,topologies[i]), (:demand,"$(d)/$(num_demands)"), (:paths,"KSP-$p")]);
                                 TEAVAR(env, links, capacity, flows, demand, b, ksp[p], T, Tf, scenarios[i],probs[i])), x_vals)
                for j in 1:length(vals)
                    push!(all_var_vals[j], vals[j][2])
                end
            end
        end
        for j in 1:length(all_var_vals)
            push!(algorithmn_vals, sum(all_var_vals[j])/length(all_var_vals[j]))
        end
        push!(y_vals, algorithmn_vals)
        push!(labels, "Teavar_ksp$(ksp[p])")
    end


    # LOG OUTPUTS
    dir = nextRun(dirname)
    z = zeros(length(x_vals), length(y_vals) + 1)
    z[:,1] = x_vals
    for i in 1:length(y_vals)
        z[:,i+1] = y_vals[i]
    end
    writedlm("$dir/vals", z)

    # PLOT
    if plot
        PyPlot.clf()
        for i in 1:size(y_vals, 1)
            PyPlot.plot(x_vals, y_vals[i])
        end
        PyPlot.xlabel("Availability", fontweight="bold")
        PyPlot.ylabel("Beta Tail Loss", fontweight="bold")
        PyPlot.legend(labels, loc="upper right")
        PyPlot.savefig("$(dir)/plot.png")
        PyPlot.show()
    end
end

# pathSelection(["./data/B4", "./data/IBM"],
#                      [4000, 4000],
#                      ["SMORE", "FFC"],
#                      6,
#                      [.9, .92, .94, .96, .98, .99],
#                      .0001,
#                      ksp=[4,6],
#                      weibull=true)
