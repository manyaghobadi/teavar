using DelimitedFiles, ProgressMeter, PyPlot

include("./util.jl")
include("./parsers.jl")
include("./Algorithms/TEAVAR.jl")
include("./Algorithms/FFC.jl")
include("./simulation.jl")

function getThroughputGuarantees(x_vals,
                                 cutoff,
                                 topologies,
                                 num_demands,
                                 iterations;
                                 plot=true,
                                 dirname="./data/raw/guarantees/")
    env = Gurobi.Env()
    k = 20
    downscale_capacity = 1
    downscale_demand = 1

    # GRAPH STUFF
    cvar_satisfied = []
    cvar_min = []
    cvar_user_satisfied = []

    ## COMPUTE SCENARIOS
    ffc1_coverages = []
    ffc2_coverages = []
    scenarios_all = []
    scenario_probs_all = []
    for t in 1:length(topologies)
        topology = topologies[t]
        links, capacity, link_probs, nodes = readTopology(topology, downscale=downscale_capacity)
        scenarios_all_top = []
        scenario_probs_top = []
        for i in 1:iterations
            link_probs = weibullProbs(length(links), shape=.8, scale=.0005)
            _, probffc = kScenarios(length(links), 1, link_probs, first=true)
            push!(ffc1_coverages, sum(probffc))
            _, probffc = kScenarios(length(links), 2, link_probs, first=true)
            push!(ffc2_coverages, sum(probffc))
            scenarios, probs = subScenarios(link_probs, cutoff, first=true, last=true)
            push!(scenarios_all_top, scenarios)
            push!(scenario_probs_top, probs)
        end
        push!(scenarios_all, scenarios_all_top)
        push!(scenario_probs_all, scenario_probs_top)
    end
    ffc1_coverage = sum(ffc1_coverages)/length(ffc1_coverages)
    ffc2_coverage = sum(ffc2_coverages)/length(ffc2_coverages)
    
    ## COMPUTE TEAVAR
    progress = ProgressMeter.Progress(length(x_vals) * iterations * num_demands * length(topologies), .1, "Computing TEAVAR...", 50)
    for b in x_vals
        beta_satisfied = 0
        beta_min = 0
        for t in 1:length(topologies)
            topology = topologies[t]
            links, capacity, link_probs, nodes = readTopology(topology, downscale=downscale_capacity)
            for d in 1:num_demands
                for i in 1:iterations
                    scenarios = scenarios_all[t][i]
                    probs = scenario_probs_all[t][i]
                    demand, flows = readDemand("$(topology)/demand", length(nodes), d, scale=1, downscale=downscale_demand, matrix=true)
                    T, Tf, g = getTunnels(nodes, links, capacity, flows, k, edge_disjoint=false)
                    var, cvar, a = TEAVAR(env, links, capacity, flows, demand, b, k, T, Tf, scenarios, probs)
                    allowed = demand .* (1-var)
                    beta_satisfied += sum(allowed)/sum(demand)
                    
                    # if length(user_satisfied) == 0
                        # user_satisfied = zeros(length(demand))
                    # end
                    # for user in 1:length(allowed)
                        # user_satisfied[user] += allowed[user]/demand[user]
                    # end
                    push!(cvar_user_satisfied, allowed ./ demand)
                    beta_min += minimum(allowed ./ demand)
                    ProgressMeter.next!(progress, showvalues = [(:beta, b), (:iterations, i), (:num_demands, d), (:satisfied, sum(allowed)/sum(demand)), (:min, minimum(allowed ./ demand))])
                end
            end
        end
        push!(cvar_satisfied, sum(beta_satisfied)/(iterations * num_demands * length(topologies)))
        push!(cvar_min, sum(beta_min)/(iterations * num_demands * length(topologies)))
    end

    # COMPUTE FFC-1
    d_satisfied = 0
    d_min = 0
    ffc1_user = []
    progress = ProgressMeter.Progress(num_demands * length(topologies), .1, "Computing FFC1...", 50)
    for t in 1:length(topologies)
        d_user = []
        topology = topologies[t]
        links, capacity, link_probs, nodes = readTopology(topology, downscale=downscale_capacity)
        for d in 1:num_demands
            demand, flows = readDemand("$(topology)/demand", length(nodes), d, scale=1, downscale=downscale_demand, matrix=true)
            T, Tf, g = getTunnels(nodes, links, capacity, flows, k, edge_disjoint=true)
            a, b = FFC(links, capacity, flows, demand, 1, T, Tf)
            d_satisfied += sum(b)/sum(demand)
            d_min += minimum(b ./ demand)
            # if length(d_user) == 0
            #     d_user = zeros(length(demand))
            # end
            # for user in 1:length(b)
            #     d_user[user] += b[user]/demand[user]
            # end
            push!(ffc1_user, b ./ demand)
            ProgressMeter.next!(progress, showvalues = [(:num_demands, d), (:satisfied, sum(b)/sum(demand)), (:min, minimum(b ./ demand))])
        end
    end
    ffc1_satisfied = d_satisfied/(num_demands * length(topologies))
    ffc1_min = d_min/(num_demands * length(topologies))
    y_vals_ffc1 = []
    for b in x_vals
        if b < ffc1_coverage
            push!(y_vals_ffc1, ffc1_satisfied)
        else
            push!(y_vals_ffc1, 0)
        end
    end

    ## COMPUTE FFC-2
    d_satisfied = 0
    d_min = 0
    ffc2_user = []
    progress = ProgressMeter.Progress(num_demands * length(topologies), .1, "Computing FFC2...", 50)
    for t in 1:length(topologies)
        d_user = []
        topology = topologies[t]
        links, capacity, link_probs, nodes = readTopology(topology, downscale=downscale_capacity)
        for d in 1:num_demands
            demand, flows = readDemand("$(topology)/demand", length(nodes), d, scale=1, downscale=downscale_demand, matrix=true)
            T, Tf, g = getTunnels(nodes, links, capacity, flows, k, edge_disjoint=true)
            a, b = FFC(links, capacity, flows, demand, 2, T, Tf)
            d_satisfied += sum(b)/sum(demand)
            d_min += minimum(b ./ demand)
            # if length(d_user) == 0
                # d_user = zeros(length(demand))
            # end
            # for user in 1:length(b)
                # d_user[user] += b[user]/demand[user]
            # end
            push!(ffc2_user, b ./ demand)
            ProgressMeter.next!(progress, showvalues = [(:num_demands, d), (:satisfied, sum(b)/sum(demand)), (:min, minimum(b ./ demand))])
        end
        # push!(ffc2_user, d_user ./ (num_demands * length(topologies)))
    end
    ffc2_satisfied = d_satisfied/(num_demands * length(topologies))
    ffc2_min = d_min/(num_demands * length(topologies))
    y_vals_ffc2 = []
    for b in x_vals
        if b < ffc2_coverage
            push!(y_vals_ffc2, ffc2_satisfied)
        else
            push!(y_vals_ffc2, 0)
        end
    end


    # LOG OUTPUTS
    dir = nextRun(dirname)
    writedlm("$(dir)/x_vals", x_vals)
    writedlm("$(dir)/cvar_satisfied", cvar_satisfied)
    writedlm("$(dir)/cvar_min", cvar_min)
    writedlm("$(dir)/cvar_user", cvar_user_satisfied)
    writedlm("$(dir)/ffc1_min", ffc1_min)
    writedlm("$(dir)/ffc2_min", ffc2_min)
    writedlm("$(dir)/y_vals_ffc1", y_vals_ffc1)
    writedlm("$(dir)/y_vals_ffc2", y_vals_ffc2)
    writedlm("$(dir)/ffc1_user", ffc1_user)
    writedlm("$(dir)/ffc2_user", ffc2_user)
    writedlm("$(dir)/params", [["cutoff", "topologies", "num_demands", "iterations"], [cutoff, topologies, num_demands, iterations]])
    Z = zeros(length(x_vals), 4)
    Z[:,1] = x_vals
    Z[:,2] = cvar_satisfied
    Z[:,3] = y_vals_ffc1
    Z[:,4] = y_vals_ffc2
    writedlm("$(dir)/data", Z)

    # GRAPH
    if plot
        PyPlot.clf()
        PyPlot.plot(x_vals, cvar_satisfied)
        PyPlot.plot(x_vals, y_vals_ffc1)
        PyPlot.plot(x_vals, y_vals_ffc2)
        PyPlot.legend(["TEAVAR", "FFC_1", "FFC_2"], loc="upper right")
        PyPlot.title("Throughput Guarantees")
        PyPlot.xlabel("Beta", fontweight="bold")
        PyPlot.ylabel("Throughput Guarantee for All Flows", fontweight="bold")
        PyPlot.savefig("$(dir)/plot.png")
        PyPlot.show()
    end
end

# getThroughputGuarantees([.99, .999, .9999, .99995, .99999], .00000003, ["./data/IBM", "./data/B4"], 2, 2)

function CDF(num_beta, num)
    cvar_user = readdlm("./data/raw/guarantees/$(num)/cvar_user")
    ffc1_user = readdlm("./data/raw/guarantees/$(num)/ffc1_user")
    ffc2_user = readdlm("./data/raw/guarantees/$(num)/ffc2_user")

    # println(cvar_user)
    cvar_all = [[] for i in 1:num_beta]
    b_num = 0
    for i in 1:size(cvar_user, 1)
        if mod(i, size(cvar_user, 1) / num_beta) == 1
            b_num += 1
        end
        for j in 1:size(cvar_user, 2)
            if cvar_user[i,j] != ""
                push!(cvar_all[b_num], cvar_user[i,j])
            end
        end
    end

    ffc1_all = []
    for i in 1:size(ffc1_user, 1)
        for j in 1:size(ffc1_user, 2)
            if ffc1_user[i,j] != ""
                push!(ffc1_all, ffc1_user[i,j])
            end
        end
    end

    ffc2_all = []
    for i in 1:size(ffc2_user, 1)
        for j in 1:size(ffc2_user, 2)
            if ffc2_user[i,j] != ""
                push!(ffc2_all, ffc2_user[i,j])
            end
        end
    end

    PyPlot.clf()
    labels = []
    for (i,vals) in enumerate(cvar_all)
        sorted = sort(vals)
        x_vals = sorted
        # y_vals = cumsum(sorted) ./ sum(sorted)
        y_vals = cumsum(ones(length(sorted)) ./ sum(ones(length(sorted))))
        Z = zeros(length(x_vals), 2)
        Z[:,1] = x_vals
        Z[:,2] = y_vals
        writedlm("./gnuplot/data/guarantee/$(i)", Z)
        push!(labels, x_vals[i])
        PyPlot.plot(vcat(0, x_vals, 1), vcat(0, y_vals, 1))
    end

    sorted = sort(ffc1_all)
    x_vals = sorted
    # y_vals = cumsum(sorted) ./ sum(sorted)
    y_vals = cumsum(ones(length(sorted)) ./ sum(ones(length(sorted))))
    Z = zeros(length(x_vals), 2)
    Z[:,1] = x_vals
    Z[:,2] = y_vals
    writedlm("./gnuplot/data/guarantee/ffc_1", Z)
    push!(labels, "FFC_1")
    PyPlot.plot(vcat(0, x_vals, 1), vcat(0, y_vals, 1))

    sorted = sort(ffc2_all)
    x_vals = sorted
    # y_vals = cumsum(sorted) ./ sum(sorted)
    y_vals = cumsum(ones(length(sorted)) ./ sum(ones(length(sorted))))
    Z = zeros(length(x_vals), 2)
    Z[:,1] = x_vals
    Z[:,2] = y_vals
    writedlm("./gnuplot/data/guarantee/ffc_2", Z)
    push!(labels, "FFC_2")
    PyPlot.plot(vcat(0, x_vals, 1), vcat(0, y_vals, 1))

    PyPlot.title("title")
    PyPlot.xlabel("val", fontweight="bold")
    PyPlot.ylabel("prob", fontweight="bold")
    PyPlot.legend(labels, loc="lower right")
    PyPlot.show()
end

# CDF(3, 55)