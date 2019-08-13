# Pkg.add("JuMP")

using JuMP, Gurobi

env = Gurobi.Env()

function CVaR(edges,
              capacity,
              flows,
              demand,
              probabilities,
              cutoff,
              beta,
              k,
              T,
              Tf;
              scenarios=nothing,
              scenario_probs=nothing,
              allocations=nothing,
              ffc=false,
              nodes=[],
              graph=nothing,
              explain=false,
              verbose=false,
              utilization=false,
              draw=false,
              logging=false)

    nedges = size(edges,1)
    nflows = size(flows,1)
    ntunnels = size(T,1)

    # CREATE ALL SCENARIOS
    # scenarios = allScenarios(nedges)

    # CREATE SCENARIOS
    if scenarios == nothing
        scenarios, p = subScenarios(probabilities, cutoff, first=false, last=false)
        nscenarios = size(scenarios,1)
    else
        nscenarios = size(scenarios,1)
        p = scenario_probs
    end

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
                            X[s,t] = 0
                        end
                    end
                end
            end
        end
    end

    #CREATE TUNNEL SCENARIO MATRIX
    # X  = ones(nscenarios,ntunnels)
    # for s in 1:nscenarios
    #     for t in 1:ntunnels
    #         if size(T[t],1) == 0
    #             X[s,t] = 0
    #         else
    #             for e in 1:nedges
    #                 if scenarios[s][e] == 0
    #                     if in(e, T[t])
    #                         X[s,t] = 0
    #                     end
    #                 end
    #             end
    #         end
    #     end
    # end

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

    # EDGE CONSTRAINTS:  overlapping flows cannot add up to the capacity of that link
    # for s in 1:nscenarios
        for e in 1:nedges
            @constraint(model, sum(a[f,t] * L[Tf[f][t],e] for f in 1:nflows, t in 1:size(Tf[f],1)) <= capacity[e])
        end
    # end

    # for f in 1:nflows
        # @constraint(model, sum(a[f,t] for t in 1:size(Tf[f],1)) >= 2*demand[f])
        # for t in 1:size(Tf[f],1)
        #     @constraint(model, a[f,t] <= demand[f])
        #     if length(T[Tf[f][t]]) == 0
        #         @constraint(model, a[f,t] == 0)
        #     end
        # end
    # end

    # SCENARIO LOSS PER FLOW
    @expression(model, satisfied[s=1:nscenarios, f=1:nflows], sum(a[f,t] * X[s,Tf[f][t]] for t in 1:size(Tf[f],1)) / demand[f])

    for s in 1:nscenarios
        for f in 1:nflows
            # @constraint(model, (demand[f] - sum(a[f,t] * X[s,Tf[f][t]] for t in 1:size(Tf[f],1))) / demand[f] <= u[s,f])
            # @expression(model, satisfied, sum(a[f,t] * X[s,Tf[f][t]] for t in 1:size(Tf[f],1)) / demand[f])
            @constraint(model, u[s,f] >= 1 - satisfied[s,f])
            # @constraint(model, (demand[f] - sum(x[Tf[f][t]] * X[s,Tf[f][t]] for t in 1:size(Tf[f],1))) / demand[f] == u[s,f])
        end
    end

    # SCENARIO OVERALL LOSS
    for s in 1:nscenarios
        # @constraint(model, umax[s] + alpha >= 0)
    end

    # @expression(model, avg_loss[s=1:nscenarios], sum(u[s,f]*demand[f] for f in 1:nflows) / sum(demand))
    # @expression(model, avg_loss[s=1:nscenarios], sum(u[s,f] for f in 1:nflows) / nflows)
    for s in 1:nscenarios
        # @constraint(model, umax[s] + alpha == (sum(u[s,f] for f in 1:nflows) / nflows))
        # @constraint(model, umax[s] + alpha - avg_loss[s] == 0)

        for f in 1:nflows
            @constraint(model, umax[s] + alpha >= u[s,f])
        end
    end

    if allocations != nothing
        @constraint(model, a .== allocations)
    end

    @objective(model, Min, alpha + (1 / (1 - beta)) * sum((p[s] * umax[s] for s in 1:nscenarios)))
    # println(model)


    bbdata = NodeData[]
    data = []

    function infocallback(cb)
        node      = MathProgBase.cbgetexplorednodes(cb)
        obj       = MathProgBase.cbgetobj(cb)
        bestbound = MathProgBase.cbgetbestbound(cb)
        push!(data, (cb, bestbound, time()))
    end
    addinfocallback(model, infocallback, when = :Intermediate)

    # function corners(cb)
    #     for e in 1:nedges
    #         @lazyconstraint(cb, sum(a[f,t] * L[Tf[f][t],e] for f in 1:nflows, t in 1:size(Tf[f],1)) <= capacity[e])
    #     end
    # end
    # addlazycallback(model, corners)
    solve(model)

    if (logging)
        # Save results to file for analysis later
        id = Int(readdlm("./data/optimizer/counter.txt")[1])
        writedlm("./data/optimizer/counter.txt", Int(id + 1))
        dir = "./data/optimizer/id_$(id)"
        mkdir(dir)
        writedlm("$(dir)/scenarios", scenarios)
        writedlm("$(dir)/probs", p)
        writedlm("$(dir)/a", getvalue(a))
        writedlm("$(dir)/Tf", Tf)
        writedlm("$(dir)/T", T)
        writedlm("$(dir)/edges", edges)
        writedlm("$(dir)/capacity", capacity)
        writedlm("$(dir)/params", ["cutoff" "beta"; cutoff beta])
        writedlm("$(dir)/vals", ["var" "cvar"; getvalue(alpha) getobjectivevalue(model)])
        writedlm("$(dir)/statistics", ["time" "numlineconstr" "nodecount" "objbound" "objvalue";
            getsolvetime(model) MathProgBase.numlinconstr(model) getnodecount(model) getobjbound(model) getobjectivevalue(model)])
    end

    if (explain)
        printResults(getobjectivevalue(model), alpha, a, u, umax, edges, scenarios, T, Tf, L, capacity, verbose=verbose, utilization=utilization)
    end
    if (draw)
        drawGraphs(getvalue(a), L, edges, nodes)
    end

    return (getvalue(alpha), getobjectivevalue(model), getvalue(a))
end

