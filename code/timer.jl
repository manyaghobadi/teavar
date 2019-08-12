using DelimitedFiles, ProgressMeter, PyPlot, Gurobi

include("./util.jl")
include("./parsers.jl")
include("./Algorithms/TEAVAR.jl")

function timeScenarios(cutoffs, iterations, weibull=true, shape=.8, scale=.0001)
    x_vals = [18, 22, 26, 30, 34, 38, 42, 46, 50, 54, 58, 62, 66, 70, 74, 78, 82, 86, 90, 94, 100, 104, 108, 112]
    y_vals = [[] for i=1:length(cutoffs) + 1]
    p = Progress(length(x_vals)*iterations*(length(cutoffs)+1), .1, "Scenario Times...", 50)
    for k in 1:length(x_vals)
        vals = zeros(length(cutoffs) + 1)
        for i in 1:iterations
            if weibull
                probabilities = weibullProbs(x_vals[k], shape=.8, scale=.0001)
            else
                probabilities = map(n -> rand(n) .* 2 ./ 10, iterations)
            end
            cutoff = (sum(probabilities)/length(probabilities))^3
            next = @elapsed subScenariosRecursion(probabilities, cutoff)
            next!(p, showvalues = [(:x_vals,"$(k)/$(length(x_vals))"), (:iterations,"$(i)/$(iterations)"), (:cutoffs,cutoff), (:last, next)])
            vals[1] += next
            for j in 1:length(cutoffs)
                next = @elapsed subScenariosRecursion(probabilities, cutoffs[j])
                next!(p, showvalues = [(:x_vals,"$(k)/$(length(x_vals))"), (:iterations,"$(i)/$(iterations)"), (:cutoff,cutoffs[j]), (:last, next)])
                vals[j+1] += next
            end
        end
        vals ./ iterations
        for v in 1:length(vals)
            push!(y_vals[v], vals[v])
        end
    end

    z = zeros(length(x_vals), length(y_vals) + 1)
    z[:,1] = x_vals
    for i in 1:length(y_vals)
        z[:,i+1] = y_vals[i]
    end
    writedlm("./data/raw/time_scenarios/x_vals", x_vals)
    writedlm("./data/raw/time_scenarios/y_vals", y_vals)
    writedlm("./data/raw/time_scenarios/z", z)
end

function timeOptimizer(topologies,
                       cutoffs,
                       iterations;
                       weibull=true,
                       shape=.8,
                       scale=.0001,
                       paths="SMORE",
                       plot=true,
                       beta=.9,
                       demand_num=1,
                       dirname="./data/raw/time_optimizer")
                       
    env = Gurobi.Env()

    y_vals = [[] for i=1:length(cutoffs) + 1]
    x_vals = []

    p = Progress(length(topologies)*iterations*(length(cutoffs)+1), .1, "Scenario Times...", 50)
    for t in 1:length(topologies)
        vals = zeros(length(cutoffs) + 1)
        links, capacity, link_probs, nodes = readTopology(topologies[t])
        demand, flows = readDemand("$(topologies[t])/demand", length(nodes), demand_num, matrix=true)
        T, Tf, k = parsePaths("$(topologies[t])/paths/$(paths)", links, flows)
        push!(x_vals, length(links))
        
        for i in 1:iterations
            if weibull
                probabilities = weibullProbs(length(links), shape=.8, scale=.0001)
            else
                probabilities = map(n -> rand(n) .* 2 ./ 10, iterations)
            end

            ## OPTIMAL
            cutoff = (sum(probabilities)/length(probabilities))^2
            scenarios, scenario_probs = subScenariosRecursion(probabilities, cutoff)
            next = @elapsed TEAVAR(env, links, capacity, flows, demand, beta, k, T, Tf, scenarios, scenario_probs)
            next!(p, showvalues = [(:topologies,"$(t)/$(length(topologies))"), (:iterations,"$(i)/$(iterations)"), (:cutoffs,cutoff), (:last, next)])
            vals[1] += next

            ## OTHERS
            for j in 1:length(cutoffs)
                scenarios, scenario_probs = subScenariosRecursion(probabilities, cutoffs[j])
                next = @elapsed TEAVAR(env, links, capacity, flows, demand, beta, k, T, Tf, scenarios, scenario_probs)
                next!(p, showvalues = [(:topologies,"$(t)/$(length(topologies))"), (:iterations,"$(i)/$(iterations)"), (:cutoff,cutoffs[j]), (:last, next)])
                vals[j+1] += next
            end
        end
        vals ./ iterations
        for v in 1:length(vals)
            push!(y_vals[v], vals[v])
        end
    end

    # LOG RESULTS
    dir = nextRun(dirname)
    z = zeros(length(x_vals), length(y_vals) + 1)
    z[:,1] = x_vals
    for i in 1:length(y_vals)
        z[:,i+1] = y_vals[i]
    end
    writedlm("$(dir)/x_vals", x_vals)
    writedlm("$(dir)/y_vals", y_vals)
    writedlm("$(dir)/z", z)

    # PLOT
    if plot
        PyPlot.clf()
        for i in 1:length(y_vals)
            PyPlot.plot(x_vals, y_vals[i])
        end
        PyPlot.xlabel("Number of Edges", fontweight="bold")
        PyPlot.ylabel("Time (s)", fontweight="bold")
        PyPlot.legend(pushfirst!(map(elt -> string(elt), cutoffs), "near optimal"), loc="lower right")
        PyPlot.show()
    end
end

# timeOptimizer(["./data/B4", "./data/IBM"], [.001, .0001, .00001, .000001, .0000001], 2)
# timeScenarios([.001, .0001, .00001, .000001, .0000001], 200)
