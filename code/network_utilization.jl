using DelimitedFiles, ProgressMeter, PyPlot, Gurobi

include("./util.jl")
include("./parsers.jl")
include("./Algorithms/TEAVAR.jl")
include("./Algorithms/FFC.jl")
include("./simulation.jl")

function network_utilization(topology,
                            demand_downscale,
                            capacity_downscale,
                            num_demands,
                            iterations,
                            cutoff,
                            availabilities;
                            k=20,
                            paths="SMORE",
                            weibull_scale=.0001,
                            plot=true,
                            dirname="./data/raw/utilization")

    env = Gurobi.Env()
    dir = nextRun(dirname)

    scenarios_all = []
    scenario_probs_all = []
    links, capacity, link_probs, nodes = readTopology(topology, downscale=1)
    for i in 1:iterations
        link_probs = weibullProbs(length(links), shape=.8, scale=.0005)
        scenarios, probs = subScenarios(link_probs, cutoff, first=true, last=true)
        push!(scenarios_all, scenarios)
        push!(scenario_probs_all, probs)
    end
    links, capacity, link_probs, nodes = readTopology(topology, downscale=1)


    min_routed = 0
    max_routed = Inf
    progress = ProgressMeter.Progress(num_demands*iterations*length(availabilities), .1, "Computing Utilization Plot for TEAVAR...", 50)

    throughputs_teavar = [[] for i in 1:length(availabilities)]
    edge_utilization_percentages = [[] for i in 1:length(availabilities)]
    for b in 1:length(availabilities)
        throughputs = []
        edge_utilizations = []
        for d in 1:num_demands
            avg_throughput = 0
            for i in 1:iterations
                scenarios = scenarios_all[i]
                probs = scenario_probs_all[i]
                demand, flows = readDemand("$(topology)/demand", length(nodes), d, scale=1, downscale=demand_downscale, matrix=true)
                T, Tf, g = getTunnels(nodes, links, capacity, flows, k, edge_disjoint=false)
                var, cvar, a = TEAVAR(env, links, capacity, flows, demand, availabilities[b], k, T, Tf, scenarios, probs)
                # beta_satisfied += sum(allowed)/sum(demand)
                bandwidth_allowed = ones(length(flows)) * (1-var)
                edge_utilization, routed = simulateUtilizationNoFailures(links, capacity, demand, flows, T, Tf, k, a, bandwidth_allowed)
                edge_utilization_percentage = edge_utilization ./ capacity
                throughput = sum(routed)
                min_routed = min(throughput, min_routed)
                max_routed = max(throughput, max_routed)

                avg_throughput += throughput
                push!(throughputs, throughput)
                push!(edge_utilizations, edge_utilization)
                edge_utilization_percentages[b] = vcat(edge_utilization_percentages[b], edge_utilization_percentage)
                ProgressMeter.next!(progress, showvalues = [(:beta, availabilities[b]), (:iterations, i), (:num_demands, d), (:throughput, throughput)])
            end
            push!(throughputs_teavar[b], avg_throughput/iterations)
        end
        writedlm("$(dir)/$(availabilities[b])_throughputs", throughputs)
        writedlm("$(dir)/$(availabilities[b])_utilization", edge_utilizations)
        writedlm("$(dir)/$(availabilities[b])_utilization_percentage", edge_utilization_percentages)
    end

    progress = ProgressMeter.Progress(num_demands, .1, "Computing Utilization Plot for FFC1...", 50)
    throughputs_ffc1 = []
    edge_utilizations_ffc1 = []
    edge_utilization_percentages_ffc1 = []
    for d in 1:num_demands
        demand, flows = readDemand("$(topology)/demand", length(nodes), d, scale=1, downscale=demand_downscale, matrix=true)
        # T, Tf, g = getTunnels(nodes, links, capacity, flows, k, edge_disjoint=false)
        T, Tf, g = getTunnels(nodes, links, capacity, flows, k, edge_disjoint=true)
        a, b = FFC(env, links, capacity, flows, demand, 1, T, Tf)
        bandwidth_allowed = ones(length(flows)) .* (b ./ demand)
        edge_utilization, routed = simulateUtilizationNoFailures(links, capacity, demand, flows, T, Tf, k, a, bandwidth_allowed)
        edge_utilization_percentage = edge_utilization ./ capacity
        throughput = sum(routed)
        min_routed = min(throughput, min_routed)
        max_routed = max(throughput, max_routed)

        push!(throughputs_ffc1, throughput)
        push!(edge_utilizations_ffc1, edge_utilization)
        # push!(edge_utilization_percentages_ffc1, edge_utilization_percentage)
        edge_utilization_percentages_ffc1 = vcat(edge_utilization_percentages_ffc1, edge_utilization_percentage)
        ProgressMeter.next!(progress, showvalues = [(:num_demands, d), (:throughput, throughput)])
    end
    writedlm("$(dir)/FFC1_throughputs", throughputs_ffc1)
    writedlm("$(dir)/FFC1_utilization", edge_utilizations_ffc1)
    writedlm("$(dir)/FFC1_utilization_percentage", edge_utilization_percentages_ffc1)


    progress = ProgressMeter.Progress(num_demands, .1, "Computing Utilization Plot for FFC2...", 50)
    throughputs_ffc2 = []
    edge_utilizations_ffc2 = []
    edge_utilization_percentages_ffc2 = []
    for d in 1:num_demands
        demand, flows = readDemand("$(topology)/demand", length(nodes), d, scale=1, downscale=demand_downscale, matrix=true)
        # T, Tf, g = getTunnels(nodes, links, capacity, flows, k, edge_disjoint=false)
        T, Tf, g = getTunnels(nodes, links, capacity, flows, k, edge_disjoint=true)
        a, b = FFC(env, links, capacity, flows, demand, 2, T, Tf)
        bandwidth_allowed = ones(length(flows)) .* (b ./ demand)
        edge_utilization, routed = simulateUtilizationNoFailures(links, capacity, demand, flows, T, Tf, k, a, bandwidth_allowed)
        edge_utilization_percentage = edge_utilization ./ capacity
        throughput = sum(routed)
        min_routed = min(throughput, min_routed)
        max_routed = max(throughput, max_routed)

        push!(throughputs_ffc2, throughput)
        push!(edge_utilizations_ffc2, edge_utilization)
        # push!(edge_utilization_percentages_ffc2, edge_utilization_percentage)
        edge_utilization_percentages_ffc2 = vcat(edge_utilization_percentages_ffc2, edge_utilization_percentage)
        ProgressMeter.next!(progress, showvalues = [(:num_demands, d), (:throughput, throughput)])
    end
    writedlm("$(dir)/FFC2_throughputs", throughputs_ffc2)
    writedlm("$(dir)/FFC2_utilization", edge_utilizations_ffc2)
    writedlm("$(dir)/FFC2_utilization_percentage", edge_utilization_percentages_ffc2)
    writedlm("$(dir)/params", [[ "topology", "demand_downscale", "capacity_downscale", "num_demands", "iterations", "cutoff", "availabilities"], [topology, demand_downscale, capacity_downscale, num_demands, iterations, cutoff, availabilities]])

    if plot
        # PyPlot.clf()
        # println(num_demands)
        # println(iterations)
        # x_vals = collect(1:num_demands)
        # for b in 1:length(availabilities)
        #     PyPlot.plot(x_vals, throughputs_teavar[b])
        # end
        # PyPlot.plot(x_vals, throughputs_ffc1)
        # PyPlot.plot(x_vals, throughputs_ffc2)
        # PyPlot.legend(vcat(map(elt -> string(elt), availabilities), ["FFC_1", "FFC_2"]), loc="upper right")
        # PyPlot.title("CVaR Graph")
        # PyPlot.xlabel("Demand Number", fontweight="bold")
        # PyPlot.ylabel("Throughput", fontweight="bold")
        # PyPlot.show()
        CDF(availabilities, edge_utilization_percentages, edge_utilization_percentages_ffc1, edge_utilization_percentages_ffc2, dir)
    end

end

# network_utilization(["TEAVAR", "FFC-1", "FFC-2"], "B4", 1, 1, 3, 1, .00001, [.99, .999, .9999])

function CDF(availabilities, edge_utilization_percentages_teavar, edge_utilization_percentages_ffc1, edge_utilization_percentages_ffc2, dir)
    PyPlot.clf()
    labels = []
    for (i,vals) in enumerate(edge_utilization_percentages_teavar)
        sorted = sort(vals)
        x_vals = sorted
        # y_vals = cumsum(sorted) ./ sum(sorted)
        y_vals = cumsum(ones(length(sorted)) ./ sum(ones(length(sorted))))
        Z = zeros(length(x_vals), 2)
        Z[:,1] = x_vals
        Z[:,2] = y_vals
        # writedlm("./gnuplot/data/guarantee/$(i)", Z)
        push!(labels, string(availabilities[i]))
        PyPlot.plot(vcat(0, x_vals, 1), vcat(0, y_vals, 1))
    end

    sorted = sort(edge_utilization_percentages_ffc1)
    x_vals = sorted
    # y_vals = cumsum(sorted) ./ sum(sorted)
    y_vals = cumsum(ones(length(sorted)) ./ sum(ones(length(sorted))))
    Z = zeros(length(x_vals), 2)
    Z[:,1] = x_vals
    Z[:,2] = y_vals
    # writedlm("./gnuplot/data/guarantee/ffc_1", Z)
    push!(labels, "FFC_1")
    PyPlot.plot(vcat(0, x_vals, 1), vcat(0, y_vals, 1))

    sorted = sort(edge_utilization_percentages_ffc2)
    x_vals = sorted
    # y_vals = cumsum(sorted) ./ sum(sorted)
    y_vals = cumsum(ones(length(sorted)) ./ sum(ones(length(sorted))))
    Z = zeros(length(x_vals), 2)
    Z[:,1] = x_vals
    Z[:,2] = y_vals
    # writedlm("./gnuplot/data/guarantee/ffc_2", Z)
    push!(labels, "FFC_2")
    PyPlot.plot(vcat(0, x_vals, 1), vcat(0, y_vals, 1))
    PyPlot.title("title")
    PyPlot.xlabel("Utilization Percentage", fontweight="bold")
    PyPlot.ylabel("CDF", fontweight="bold")
    PyPlot.legend(labels, loc="lower right")
    PyPlot.savefig("$(dir)/plot.png")
    PyPlot.show()
end