using Random

include("./util.jl")
include("./parsers.jl")
include("./Algorithms/TEAVAR.jl")

# Partitions the vector x into n subvectors, each at least of length div(length(x) / n) and at most of ciel(length(x) / n);
# in other words, the subvectors' lengths will be as evenly distributed as possible. The largest subvectors will be at the
# beginning of the vector.
function partition_evenly(x, n)
	num_elems = length(x)
	smallest_partition_size = div(num_elems, n)
	num_of_largest_partitions = mod(num_elems, n)
	partition_sizes = ones(Int64, n + 1) * smallest_partition_size
	partition_sizes[1] = 0 # set the first element to 0, so that the cumsum gives us the correct indices later on
	partition_sizes[2:num_of_largest_partitions + 1] .+= 1 # largest partitions come at the beginning, are at most one element longer
	partition_inds = cumsum(partition_sizes)
	# partition_inds is now a Vector of indices, where the first element is 0. As we iterate over sequential pairs
	# of elements (i, j), x[i + 1:j] will give us the subvectors of x that should belong to each partition
	return [x[partition_inds[i] + 1:partition_inds[i + 1]] for i in 1:length(partition_inds) - 1]
end

# Implementation of the POP algorithm. Randomly partitions the capacities and commodities evenly into
# n subproblems.
# TODO: Implement split fraction
function POP(capacity, flows, demand; num_subproblems=2)
    num_commodities = length(flows)
    @assert(num_commodities == length(demand))
    permutation = randperm(num_commodities)
    shuffled_demand = demand[permutation]
    shuffled_flows = flows[permutation]

    popped_demands = partition_evenly(shuffled_demand, num_subproblems)
    popped_flows = partition_evenly(shuffled_flows, num_subproblems)
    # Divide capacity evenly across all subproblems; popped_capacities is a Vector of Vectors
    popped_capacities = [capacity ./ num_subproblems for i in 1:num_subproblems]

    return (popped_capacities, popped_flows, popped_demands)
end

function benchmarkPOP(topology;
                num_subproblems=2,
                weibull=true,
                shape=.8,
                scale=.0001,
                paths="SMORE",
                beta=.9,
                demand_num=1)

    links, capacity, link_probs, nodes = readTopology(topology)
    # links = (u, v) edges
    # capacity = capacities for each edge; the ith entry in `capacity`` is for the ith edge in `links`
    demand, flows = readDemand("$(topology)/demand", length(nodes), demand_num, matrix=true)
    # flows = (src, dest) pairs
    # demand = matrix that has the demand for each (src, dest) pair
    T, Tf, k = parsePaths("$(topology)/paths/$(paths)", links, flows)
    # T = the paths for this topology for all (src, dest) pairs
    # Tf = mapping of commodities to paths; the first index is the commodity id, the second is path id
    # k = max number of paths per commodity

    if weibull
        probabilities = weibullProbs(length(links), shape=.8, scale=.0001)
    else
        probabilities = map(n -> rand(n) .* 2 ./ 10, iterations)
    end

    ## Calculate the optimal probability cutoff
    cutoff = (sum(probabilities)/length(probabilities))^2
    scenarios, scenario_probs = subScenariosRecursion(probabilities, cutoff)
    popped_capacities, popped_flows, popped_demands = POP(capacity, flows, demand, num_subproblems=num_subproblems)
    pop_runtimes = zeros(num_subproblems)
    values_at_risk = zeros(num_subproblems)
    env = Gurobi.Env()
    for sub_problem in 1:num_subproblems
        println("Subproblem ", sub_problem)
        # TODO: extract Gurobi runtime from the model 
        alpha, obj_value, _, _ = TEAVAR(env, links, popped_capacities[sub_problem],
            popped_flows[sub_problem],
            popped_demands[sub_problem],
            beta,
            k,
            T,
            Tf,
            scenarios,
            scenario_probs)
        println("alpha: ", alpha, ", obj_value: ", obj_value)
        values_at_risk[sub_problem] = alpha
        # pop_runtimes[sub_problem] = runtime_per_subproblem
    end

    println("POP values at risk: ", values_at_risk)
    # println("POP runtimes: ", pop_runtimes)
    # mean_runtime = mean(pop_runtimes) # TODO: update it to using the queueing model, which hasn't been coded up yet
    # println("Mean runtime: ", mean_runtime)
end