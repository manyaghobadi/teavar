
function calculateLossReallocation(edges, capacity, demand, flows, T, Tf, k, splittingratios, scenarios, probabilities; progress=false)
    nedges = length(edges)
    nflows = length(flows)
    ntunnels = length(T)
    nscenarios = length(scenarios)

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


    #CREATE TUNNEL EDGE MATRIX
    L = zeros(ntunnels, nedges)
    for t in 1:ntunnels
        for e in 1:nedges
            if in(e, T[t])
                L[t,e] = 1
            end
        end
    end

    as = zeros(nflows,k)
    routed = zeros(nscenarios, nflows, k)
    u = zeros(nscenarios, nflows)
    t = zeros(nscenarios)

    # SCENARIO LOSS PER FLOW
    for s in 1:nscenarios
        for f in 1:nflows
            totalup = 0
            for t in 1:size(Tf[f],1)
                totalup += splittingratios[f,t] * X[s,Tf[f][t]]
            end
            if totalup == 0
                splittingratios[f,:] = splittingratios[f,:] .+ .2
                for t in 1:size(Tf[f],1)
                    totalup += splittingratios[f,t] * X[s,Tf[f][t]]
                end
            end

            for t in 1:size(Tf[f],1)
                # as[f,t] = max(as[f,t], splittingratios[f,t] / totalup * demand[f] * X[s,Tf[f][t]])
                if totalup != 0
                    routed[s,f,t] = splittingratios[f,t] / totalup * demand[f] * X[s,Tf[f][t]]
                end
            end
        end
        

        t[s] = sum(routed[s,:,:])

        congestion_loss = 0
        for e in 1:nedges
            edge_utilization = 0
            for f in 1:nflows
                edge_utilization += sum(routed[s,f,t] * L[Tf[f][t],e] *  X[s,Tf[f][t]] for t in 1:size(Tf[f],1))
                for t in enumerate(Tf[f])
                    # edge_utilization += sum(as[f,t[1]] * L[t[2],e] * X[s,t[2]])
                end
            end
            # println("Edge: ", edges[e])
            # println(max(0, edge_utilization - capacity[e]))
            congestion_loss += max(0, round((edge_utilization - capacity[e])*1000)/1000)
        end
        t[s] -= congestion_loss
    end

    umax = map(x -> round((1 - x/sum(demand))*100000)/100000, t)
    return umax
end


function PDF(losses, probabilities, sla)
    usorted = []
    psorted = []
    umodified = losses
    pmodified = probabilities
    while length(umodified) > 0
        s = argmin(umodified)
        push!(usorted, umodified[s])
        push!(psorted, pmodified[s])
        umodified = umodified[1:end .!= s]
        pmodified = pmodified[1:end .!= s]
    end

    total = 0
    loss = 0
    for s in 1:length(usorted)
        loss = usorted[s]
        if loss > sla
            break
        end
        total += psorted[s]

    end
    return total
end

function PDF(losses, sla)
    c = 0
    for s in 1:length(losses)
        if (1-losses[s]) >= sla
            c += 1
        end
    end
    return c / length(losses)
end

function VarUniform(losses, beta)
    usorted = sort(losses)
    probabilities = zeros(length(losses)) .+ 1/length(losses)

    total = 0
    loss = 0
    varindex = 0
    for s in 1:size(usorted, 1)
        total += probabilities[s]
        loss = usorted[s]
        if total >= beta
            break
        end
    end
    return loss
end

function VAR(losses, probabilities, beta)
    usorted = []
    psorted = []
    umodified = losses
    pmodified = probabilities
    while length(umodified) > 0
        s = argmin(umodified)
        push!(usorted, umodified[s])
        push!(psorted, pmodified[s])
        umodified = umodified[1:end .!= s]
        pmodified = pmodified[1:end .!= s]
    end

    total = 0
    loss = 0
    varindex = 0
    for s in 1:size(usorted, 1)
        total += psorted[s]
        loss = usorted[s]
        if total >= beta
            break
        end
    end
    return loss
end

function CVAR(losses, probabilities, beta)
    usorted = []
    psorted = []
    umodified = losses
    pmodified = probabilities
    while length(umodified) > 0
        s = argmin(umodified)
        push!(usorted, umodified[s])
        push!(psorted, pmodified[s])
        umodified = umodified[1:end .!= s]
        pmodified = pmodified[1:end .!= s]
    end

    total = 0
    loss = 0
    prob_total = 0
    for s in 1:length(usorted)
        total += psorted[s]
        if total >= beta
            prob_total += psorted[s]
            loss += usorted[s]*psorted[s]
        end
    end
    return loss / prob_total
end


function simulateUtilizationNoFailures(edges, capacity, demand, flows, T, Tf, k, a, bandwidth_allowed)
    nedges = length(edges)
    nflows = length(flows)
    ntunnels = length(T)

    #CREATE TUNNEL EDGE MATRIX
    L = zeros(ntunnels, nedges)
    for t in 1:ntunnels
        for e in 1:nedges
            if in(e, T[t])
                L[t,e] = 1
            end
        end
    end


    routed = zeros(nflows, k)
    for f in 1:nflows
        totalup = 0
        for t in 1:size(Tf[f],1)
            totalup += a[f,t]
        end
        if totalup == 0
            a[f,:] = a[f,:] .+ .2
            for t in 1:size(Tf[f],1)
                totalup += a[f,t]
            end
        end

        for t in 1:size(Tf[f],1)
            routed[f,t] = a[f,t] / totalup * bandwidth_allowed[f] * demand[f]
        end
    end

    edge_utilization = zeros(nedges)
    edge_utilization_percentage = zeros(nedges)

    for e in 1:nedges
        for f in 1:nflows
            edge_utilization[e] += sum(routed[f,t] * L[Tf[f][t],e] for t in 1:size(Tf[f],1))
        end
        edge_utilization_percentage = edge_utilization[e]/capacity[e]
    end

    return edge_utilization, routed
end