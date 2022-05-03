using Random
using DataStructures

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
    partition_sizes[2:num_of_largest_partitions+1] .+= 1 # largest partitions come at the beginning, are at most one element longer
    partition_inds = cumsum(partition_sizes)
    # partition_inds is now a Vector of indices, where the first element is 0. As we iterate over sequential pairs
    # of elements (i, j), x[i + 1:j] will give us the subvectors of x that should belong to each partition
    return [x[partition_inds[i]+1:partition_inds[i+1]] for i = 1:length(partition_inds)-1]
end

# Implementation of the POP algorithm. Randomly partitions the capacities and commodities evenly into
# n subproblems.
# TODO: Implement split fraction
function POP(capacity, flows, demands, Tf; num_subproblems = 2)
    num_commodities = length(flows)
    @assert(num_commodities == length(demands))

    # pq = PriorityQueue(Base.Order.Reverse)
    # for i in 1:num_commodities
    #     pq[(flows[i], 0, demands[i])] = demands[i] # initialize the split_id to be 0
    # end
    # num_new_commodities = round(Int64, num_commodities * split_fraction)
    # num_commodities_after_split = num_commodities + num_new_commodities
    # while length(pq) < num_commodities_after_split
    #     flow_id, split_id, demand_value = dequeue!(pq)
    #     println("$(flow_id), $(split_id), $(demand_value)")
    #     halved_demand = demand_value / 2
    #     enqueue!(pq, (flow_id, 2 * split_id + 1, halved_demand), halved_demand)
    #     enqueue!(pq, (flow_id, 2 * split_id + 2, halved_demand), halved_demand)
    # end

    # new_flows = Array{Tuple{Int64, Int64}}(undef, (num_commodities_after_split,))
    # new_demands = zeros(Float64, num_commodities_after_split)
    # i = 1
    # while length(pq) > 0
    #     flow_id, split_id, demand_value = dequeue!(pq)
    #     new_flows[i] = flow_id
    #     new_demands[i] = demand_value
    #     i += 1
    # end

    permutation = randperm(num_commodities)
    shuffled_demand = demands[permutation]
    shuffled_flows = flows[permutation]
    shuffled_Tf = Tf[permutation]

    popped_demands = partition_evenly(shuffled_demand, num_subproblems)
    popped_flows = partition_evenly(shuffled_flows, num_subproblems)
    popped_Tf = partition_evenly(shuffled_Tf, num_subproblems)
    partitioned_permutation = partition_evenly(permutation, num_subproblems)
    # Divide capacity evenly across all subproblems; popped_capacities is a Vector of Vectors
    # popped_capacities = [capacity ./ num_subproblems for i in 1:num_subproblems]

    # Divide the capacities such that they are weighted by the fraction of demand allocated for that subproblem
    popped_capacities =
        [capacity .* sum(popped_demands[i]) / sum(demands) for i = 1:num_subproblems]
    return (
        popped_capacities,
        popped_flows,
        popped_demands,
        popped_Tf,
        partitioned_permutation,
    )
end

function updateEdgesToCommodsToFlows(
    flow_allocations,
    flows_per_subproblem,
    edges,
    T,
    Tf_per_subproblem,
    edges_to_commods_to_flows,
)
    for i = 1:size(flow_allocations, 1)
        for j = 1:size(flow_allocations, 2)
            flow_vol = flow_allocations[i, j]
            if flow_vol == 0.0
                continue
            end
            commodity = flows_per_subproblem[i]
            for e in T[Tf_per_subproblem[i][j]]
                edge = edges[e]
                if !haskey(edges_to_commods_to_flows, edge)
                    edges_to_commods_to_flows[edge] = Dict{Tuple{Int,Int},Float64}()
                end
                if !haskey(edges_to_commods_to_flows[edge], commodity)
                    edges_to_commods_to_flows[edge][commodity] = 0.0
                end
                edges_to_commods_to_flows[edge][commodity] += flow_vol
            end
        end
    end
end

function computeAggregatedObjective(
    scenarios,
    scenario_probs,
    links,
    edges_to_commods_to_flows,
    commods_to_demands,
    beta,
)
    new_umax = zeros(size(scenarios, 1))
    for s = 1:size(scenarios, 1)
        commods_to_losses_in_scenario = Dict()
        println("Scenario ", s, ":")
        for e = 1:size(scenarios[s], 1)
            if scenarios[s][e] == 0.0
                edge = links[e]
                println("Edge ", edge, " went down")
                println("Commods affected: ")
                for (commod, flow_vol) in edges_to_commods_to_flows[edge]
                    println(commod, ": ", flow_vol)
                    if !haskey(commods_to_losses_in_scenario, commod)
                        commods_to_losses_in_scenario[commod] = 0.0
                    end
                    commods_to_losses_in_scenario[commod] += flow_vol
                end
            end
        end
        for (commod, flow_lost) in commods_to_losses_in_scenario
            println(commod, ": ", flow_lost, ", ", commods_to_demands[commod])
        end
        flow_losses = [
            flow_lost / commods_to_demands[commod] for
            (commod, flow_lost) in commods_to_losses_in_scenario
        ]
        new_umax[s] = length(flow_losses) == 0 ? 0.0 : maximum(flow_losses)
    end
    return (1 / (1 - beta)) * sum(scenario_probs .* new_umax)
end

function runPOP(
    env,
    links,
    capacity,
    flows,
    demand,
    beta,
    k,
    T,
    Tf,
    scenarios,
    scenario_probs,
    num_subproblems,
)
    alphas = zeros(num_subproblems)
    obj_values = zeros(num_subproblems)
    aggregated_flow_allocations = zeros(length(flows), k)
    popped_capacities, popped_flows, popped_demands, popped_Tf, partitioned_permutation =
        POP(capacity, flows, demand, Tf, num_subproblems = num_subproblems)
    println("Commodities", flows)
    println("Permutation", partitioned_permutation)
    for sub_problem = 1:num_subproblems
        println(
            "Subproblem: ",
            sub_problem,
            ", total demand: ",
            sum(popped_demands[sub_problem]),
        )
        # TODO: extract Gurobi runtime from the model 
        # and use the queueing model to calculate the runtime
        flows_per_subproblem = popped_flows[sub_problem]
        println(flows_per_subproblem)
        Tf_per_subproblem = popped_Tf[sub_problem]
        demands_per_subproblem = popped_demands[sub_problem]
        alpha, obj_value, flow_allocations, _, _ = TEAVAR(
            env,
            links,
            popped_capacities[sub_problem],
            flows_per_subproblem,
            demands_per_subproblem,
            beta,
            k,
            T,
            Tf_per_subproblem,
            scenarios,
            scenario_probs,
        )
        println("Subproblem: ", sub_problem, ", alpha: ", alpha, ", obj_value: ", obj_value)
        println("flow allocations for subproblem", flow_allocations)
        permutation = partitioned_permutation[sub_problem]
        for i = 1:size(flow_allocations, 1)
            for j = 1:size(flow_allocations, 2)
                aggregated_flow_allocations[permutation[i], j] = flow_allocations[i, j]
            end
        end
        alphas[sub_problem] = alpha
        obj_values[sub_problem] = obj_value
    end

    println("aggregated flow allocations", aggregated_flow_allocations)

    final_alpha, final_obj_value, final_flow_allocations, _, _ = TEAVAR(
        env,
        links,
        capacity,
        flows,
        demand,
        beta,
        k,
        T,
        Tf,
        scenarios,
        scenario_probs,
        fixed_flows = aggregated_flow_allocations,
    )

    println("POP alphas: ", alphas)
    println("POP obj_values: ", obj_values)

    println("Final alpha: ", final_alpha)
    println("Final obj_value: ", final_obj_value)
end

function benchmarkPOP(
    topology;
    num_subproblems_range = [1, 2, 4, 8],
    weibull = true,
    shape = 0.8,
    scale = 0.0001,
    paths = "SMORE",
    beta = 0.9,
    demand_num = 1,
)

    links, capacity, _, nodes = readTopology(topology)
    # links = (u, v) edges
    # capacity = capacities for each edge; the ith entry in `capacity`` is for the ith edge in `links`
    demand, flows =
        readDemand("$(topology)/demand", length(nodes), demand_num, matrix = true)
    # avg_demand = mean(demand)
    # uniform_demand = rand(Uniform(avg_demand - 0.5, avg_demand + 0.5), length(demand))

    # flows = (src, dest) pairs
    # demand = matrix that has the demand for each (src, dest) pair
    T, Tf, k = parsePaths("$(topology)/paths/$(paths)", links, flows)
    # T = the paths for this topology for all (src, dest) pairs; each path is a vector of edge ids
    # Tf = mapping of commodities to paths; the first index is the commodity id, the second is path id
    # k = max number of paths per commodity

    if weibull
        probabilities = weibullProbs(length(links), shape = 0.8, scale = 0.0001)
    else
        probabilities = map(n -> rand(n) .* 2 ./ 10, iterations)
    end

    # Calculate the optimal probability cutoff
    cutoff = (sum(probabilities) / length(probabilities))^2
    scenarios, scenario_probs = subScenariosRecursion(probabilities, cutoff)
    env = Gurobi.Env()
    orig_alpha, orig_obj_value, _, _, _ = TEAVAR(
        env,
        links,
        capacity,
        flows,
        demand,
        beta,
        k,
        T,
        Tf,
        scenarios,
        scenario_probs,
        explain = false,
        verbose = false,
    )
    println("orig_alpha: ", orig_alpha, ", orig_obj_value: ", orig_obj_value)
    for num_subproblems in num_subproblems_range
        runPOP(
            env,
            links,
            capacity,
            flows,
            demand,
            beta,
            k,
            T,
            Tf,
            scenarios,
            scenario_probs,
            num_subproblems,
        )
    end
end
