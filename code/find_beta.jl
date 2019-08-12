include("./Algorithms/TEAVAR.jl")
include("./simulation.jl")
include("./util.jl")
include("./parsers.jl")

function findBeta(alpha, sigfigs, links, capacity, flows, demand, cutoff, T, Tf, k, scenarios, scenario_probs; cvar=false, allocations=nothing)

    step_size = 10.0^(-1 * sigfigs)
    low = 0
    high = 1 - step_size
    index = cvar ? 2 : 1

    while low <= high
        middle = round((low + high)/2, digits=sigfigs)
        val = allocations != nothing ?
            TEAVAR(links, capacity, flows, demand, middle, k, T, Tf, allocations=a)[index] :
            TEAVAR(links, capacity, flows, demand, middle, k, T, Tf, scenarios, scenario_probs)[index]
        if val <= alpha
            low = middle + step_size
            if (low == 1) break end
            val = allocations != nothing ?
                TEAVAR(links, capacity, flows, demand, low, k, T, Tf, allocations=a)[index] :
                TEAVAR(links, capacity, flows, demand, low, k, T, Tf, scenarios, scenario_probs)[index]
            if val > alpha
                return middle
            end
        else
            high = middle - step_size
            val = allocations != nothing ?
                TEAVAR(links, capacity, flows, demand, high, k, T, Tf, allocations=a)[index] :
                TEAVAR(links, capacity, flows, demand, high, k, T, Tf, scenarios, scenario_probs)[index]
            if val <= alpha
                return high
            end
        end
    end
    return high < .5 ? 0 : 1
end
