using JuMP, Combinatorics, Gurobi

function printResults(o, a, b, edges, T, Tf)
    println("Objective value: ", o)

    for i in 1:size(b,1)
        println("bw flow ", i, " = ", getvalue(b[i]))
    end
    print("\n")
    println("-----------------------------------------")

    for i in 1:size(a,1)
        for j in 1:size(a,2)
            println("flow ",i, ", tunnel ", j, " = ", getvalue(a[i,j]))
            print("edges in use: ")
            for e in T[Tf[i][j]]
                print(edges[e])
            end
            println("\n")
        end
    end
end



function FFC(env, edges, capacity, flows, demand, k, T, Tf; minb=0)

    nedges = size(edges,1)
    nflows = size(flows,1)
    ntunnels = size(T,1)

    # CREATE ALL SCENARIOS
    scenarios = []
    for bits in collect(combinations(1:nedges,k))
        s = ones(nedges)
        for bit in bits
            s[bit] = 0
        end
        push!(scenarios, s)
    end

    #CREATE RESIDUAL TUNNELS BY SCENARIO BY FLOW (References Tf)
    Tsf = []
    for s in 1:size(scenarios,1)
        sft = []
        for f in 1:size(Tf,1)
            ft = []
            for t in 1:size(Tf[f],1)
                up = true
                if (length(T[Tf[f][t]]) == 0)
                    up = false
                end
                for e in T[Tf[f][t]]
                    if scenarios[s][e] == 0
                        up = false
                    end
                end
                if up
                    push!(ft, t)
                end
            end
            push!(sft,ft)
        end
        push!(Tsf,sft)
    end

    #CREATE TUNNEL EDGE MATRIX
    L = zeros(ntunnels, nedges)
    for t in 1:ntunnels
        for e in 1:nedges
            if in(e, T[t])
                L[t,e] = 1
            end
        end
    end

    model = Model(solver=GurobiSolver(env, OutputFlag=0))
    @variable(model, b[1:nflows] >= 0, basename="b")
    @variable(model, a[1:nflows,1:size(Tf[1],1)] >= 0, basename="a")
    @variable(model, u >= 0, basename="u")


    for f in 1:nflows
        @constraint(model, sum(a[f,t] for t in 1:size(Tf[f],1)) >= b[f])   #the sum of all allocated bandwidths on every flow must be >= the total bandwidth for that flow
    end

    for e in 1:nedges
        @constraint(model, sum(a[f,t] * L[Tf[f][t],e] for f in 1:nflows for t in 1:size(Tf[f],1)) <= capacity[e])   #overlapping flows cannot add up to the capacity of that link
    end

    for f in 1:nflows
        for s in 1:size(scenarios,1)
            @constraint(model, sum(a[f,t] for t in Tsf[s][f]) >= b[f])   #residual tunnels must be able to carry bandwidth
        end
    end

    for f in 1:nflows
        @constraint(model, b[f] >= minb)
    end

    for f in 1:nflows
        @constraint(model, b[f] <= demand[f])   #all allocated bandwidths must be less than the demand for that flow
        for t in 1:size(Tf[f],1)
            @constraint(model, a[f,t] >= 0)     #each allocated bandwidth on for flow f on tunnel t >= 0
        end
    end

    for f in 1:nflows
        # @constraint(model, u <= b[f]/demand[f])
    end
  #   @objective(model, Max, u)

    @objective(model, Max, sum((b[i] for i in 1:size(b,1))))
    solve(model)
    # printResults(getobjectivevalue(model), a, b, edges, T, Tf)
    return getvalue(a), getvalue(b)
end
