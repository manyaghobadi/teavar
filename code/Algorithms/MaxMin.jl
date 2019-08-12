using JuMP, Gurobi

function printAllocations(a, edges, T, Tf)
    println("------------------ Allocations ----------------------\n")
    for i in 1:size(a,1)
        for j in 1:size(a,2)
            println("Flow ",i, ", tunnel ", j, " allocated : ", a[i,j])
            print("Edges in use: ")
            for e in T[Tf[i][j]]
                print(edges[e])
            end
            println("\n")
        end
    end
end

function MaxMin(env, edges, capacity, flows, demand, k, T, Tf, explain=false)
    nedges = size(edges,1)
    nflows = size(flows,1)
    ntunnels = size(T,1)

    #CREATE TUNNEL EDGE MATRIX
    L = zeros(ntunnels, nedges)
    for t in 1:ntunnels
        for e in 1:nedges
            if in(e, T[t])
                L[t,e] = 1
            end
        end
    end
    a = zeros(nflows, k)
    b = zeros(nflows) .- 1
    U = collect(1:nflows)
    i = 0
    while length(U) != 0
        a, amin = MaxMinLP(env, edges, capacity, flows, U, b, demand, k, T, Tf)
        Z = []
        for u in 1:length(U)
            if amin >= demand[U[u]]
                push!(Z, U[u])
                b[U[u]] = sum(a[U[u],:])
            end
        end
        U = filter(u -> u ∉ Z, U)
        i += 1
    end
    if explain
        printAllocations(a, edges, T, Tf)
    end
    return a
end



function MaxMinLP(env,
              edges,
              capacity,
              flows,
              U,
              b_fixed,
              demand,
              k,
              T,
              Tf)

    nedges = size(edges,1)
    nflows = size(flows,1)
    ntunnels = size(T,1)

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
    @variable(model, a[1:nflows, 1:k] >= 0, basename="a", category=:SemiCont)
    @variable(model, amin >= 0, basename="amin", category=:SemiCont)

    for e in 1:nedges
        @constraint(model, sum(a[U[u],t] * L[Tf[U[u]][t],e] for u in 1:length(U), t in 1:size(Tf[U[u]],1)) <= capacity[e])
    end


    for u in 1:length(U)
        @constraint(model, sum(a[U[u],t] for t in 1:size(Tf[U[u]],1)) <= demand[U[u]])
    end

    for f in 1:nflows
        if b_fixed[f] != -1
            @constraint(model, sum(a[f,t] for t in 1:size(Tf[f],1)) == b_fixed[f])
        end
    end

    for u in 1:length(U)
        @constraint(model, amin <= sum(a[U[u],t] for t in 1:size(Tf[U[u]],1)))
    end

    @objective(model, Max, amin)

    solve(model)
    return (getvalue(a), getvalue(amin))
end
