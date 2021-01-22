import Pkg
Pkg.add("JuMP")
Pkg.add("Gurobi")

include("../util.jl")

using JuMP, Gurobi

function TEAVAR(env,
                edges,
                capacity,
                flows,
                demand,
                beta,
                k,
                T,
                Tf,
                scenarios,
                scenario_probs;
                explain=false,
                verbose=false,
                utilization=false,
                average=false)
                
    nedges = length(edges)
    nflows = length(flows)
    ntunnels = length(T)
    nscenarios = length(scenarios)
    p = scenario_probs

    #CREATE TUNNEL SCENARIO MATRIX
    X  = ones(nscenarios,ntunnels)
    for s in 1:nscenarios
        for t in 1:ntunnels
            if size(T[t],1) == 0
                X[s,t] = 0
            else
                for e in 1:nedges
                    if scenarios[s][e] == 0
                        back_edge = findfirst(x -> x == (edges[e][2],edges[e][1]), edges)
                        if in(e, T[t]) || in(back_edge, T[t])
                        # if in(e, T[t])
                            X[s,t] = 0
                        end
                    end
                end
            end
        end
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
    @variable(model, a[1:nflows, 1:k] >= 0, basename="a", category=:SemiCont)
    @variable(model, alpha >= 0, basename="alpha", category=:SemiCont)
    @variable(model, umax[1:nscenarios] >= 0, basename="umax")
    @variable(model, u[1:nscenarios, 1:nflows] >= 0, basename="u")
 

    # for s in 1:nscenarios
    for e in 1:nedges
        @constraint(model, sum(a[f,t] * L[Tf[f][t],e] for f in 1:nflows, t in 1:size(Tf[f],1)) <= capacity[e])
    end
    # end


    # FLOW LEVEL LOSS
    @expression(model, satisfied[s=1:nscenarios, f=1:nflows], sum(a[f,t] * X[s,Tf[f][t]] for t in 1:size(Tf[f],1)) / demand[f])

    for s in 1:nscenarios
        for f in 1:nflows
            # @constraint(model, (demand[f] - sum(a[f,t] * X[s,Tf[f][t]] for t in 1:size(Tf[f],1))) / demand[f] <= u[s,f])
            @constraint(model, u[s,f] >= 1 - satisfied[s,f])
        end
    end

    # SCENARIO LEVEL LOSS
    # for s in 1:nscenarios
        # @constraint(model, umax[s] + alpha >= 0)
    # end

    for s in 1:nscenarios
        if average
            @constraint(model, umax[s] + alpha >= (sum(u[s,f] for f in 1:nflows)) / nflows)
            # @constraint(model, umax[s] + alpha >= avg_loss[s])
        else
            for f in 1:nflows
                @constraint(model, umax[s] + alpha >= u[s,f])
            end
        end
    end

    @objective(model, Min, alpha + (1 / (1 - beta)) * sum((p[s] * umax[s] for s in 1:nscenarios)))
    solve(model)


    if (explain)
        printResults(getobjectivevalue(model), getvalue(alpha), getvalue(a), getvalue(u), getvalue(umax), edges, scenarios, T, Tf, L, capacity, verbose=verbose, utilization=utilization)
    end
    
    return (getvalue(alpha), getobjectivevalue(model), getvalue(a), getvalue(umax))
end

