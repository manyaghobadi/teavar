using DelimitedFiles, LightGraphs

####################################################################################
#######################  Increment Counter and Get Next Dir  ########################
####################################################################################

function nextRun(dir)
    dir = joinpath(@__DIR__, "./$dir")
    if isfile("$(dir)/counter.txt") == false
        mkdir("$(dir)")
        writedlm("$(dir)/counter.txt", "1")
    end
    c = Int(readdlm("$(dir)/counter.txt")[1])
    writedlm("$(dir)/counter.txt", c + 1)
    newdir = "$(dir)/$(c)"
    mkdir(newdir)
    return newdir
end


####################################################################################
#############################  Read Topology  ######################################
####################################################################################

function readTopology(topology; zeroindex=false, downscale=1)
    dir = joinpath(@__DIR__, "./data/$topology")
    input_topology = readdlm("$dir/topology.txt", header=true)[1]
    input_nodes = readdlm("$dir/nodes.txt", header=true)[1]

    ignore = ()
    fromNodes = input_topology[:,1]
    toNodes = input_topology[:,2]
    capacity = input_topology[:,3] ./ downscale ./ 1000
    probabilities = input_topology[:,4]
    links = []
    for i in 1:size(fromNodes, 1)
        if (!(fromNodes[i] in ignore) && !(toNodes[i] in ignore))
            push!(links, (Int(fromNodes[i] + zeroindex), Int(toNodes[i] + zeroindex)))
        end
    end
    return links, capacity, probabilities, input_nodes
end

####################################################################################
#############################  Read Demand  ########################################
####################################################################################

function readDemand(filename, num_nodes, num_demand; scale=1.0, matrix=true, downscale=1, sigfigs=1, zeroindex=false)
    filename = joinpath(@__DIR__, "./data/$filename")    
    input_demand = matrix ? ParseMatrix("$(filename).txt", num_nodes, num_demand) : IgnoreCycles(readdlm("$(filename)/$(num_demand).txt", header=true)[1], zeroindex=zeroindex)
    fromNodes = input_demand[:,1]
    toNodes = input_demand[:,2]
    flows = map(tup -> (Int(tup[2]), Int(toNodes[tup[1]])), enumerate(fromNodes))
    # demand = map(i -> round(i / downscale * sigfigs) / sigfigs * scale + 1/sigfigs, input_demand[:,3])
    demand = input_demand[:,3] ./ downscale .* scale ./ 1000
    return demand, flows
end

function IgnoreCycles(demand; zeroindex=false)
    z = [0 0 0;]
    for row in 1:size(demand,1)
        if demand[row, 1] != demand[row, 2]
            z = vcat(z, [demand[row,1] + zeroindex demand[row, 2] + zeroindex demand[row,3];])
            # z = vcat(z, transpose(demand[row,:]))
        end
    end
    return z[2:end,:]
end

####################################################################################
#############################  Get Allocations  ####################################
####################################################################################
function parseYatesSplittingRatios(filename, k, flows; zeroindex=false)
    filename = joinpath(@__DIR__, "./data/$filename")    
    f = readdlm(filename)
    a = zeros(size(flows,1), k)
    num_flow = 0
    t = 0
    for row in 1:size(f,1)
        if "->" in f[row,:]
            fromNode = parse(Int, replace(f[row, 1], "h" => "")) + zeroindex
            toNode = parse(Int, replace(f[row, 3], "h" => "")) + zeroindex
            num_flow = findfirst(x -> x == (fromNode, toNode), flows)
            t = 1
        else
            for col in 1:size(f,2)
                if occursin("@", f[row,col])
                    a[num_flow, t] = ceil(f[row,col + 1] * 1000)/1000
                    t += 1
                    break
                end
            end
        end
    end
    return a
end


function parseYatesAllocations(filename, k, demand, flows; zeroindex=false)
    f = joinpath(@__DIR__, "./data/$filename")    
    a = zeros(size(flows,1), k)
    num_flow = 0
    t = 0
    for row in 1:size(f,1)
        if "->" in f[row,:]
            fromNode = parse(Int, replace(f[row, 1], "h" => "")) + zeroindex
            toNode = parse(Int, replace(f[row, 3], "h" => "")) + zeroindex
            num_flow = findfirst(x -> x == (fromNode, toNode), flows)
            t = 1
        else
            for col in 1:size(f,2)
                if occursin("@", f[row,col])
                    a[num_flow, t] = ceil(f[row,col + 1] * demand[num_flow] * 1000)/1000
                    t += 1
                    break
                end
            end
        end
    end
    return a
end


####################################################################################
################################  Parse Paths  #####################################
####################################################################################

function parsePaths(filename, links, flows; zeroindex=false)
    filename = joinpath(@__DIR__, "./data/$filename")
    nflows = length(flows)
    x = readdlm(filename)
    T = []
    Tf = [[] for i=1:nflows]
    tf = []
    fromNode = 0
    toNode = 0
    num_flow = 0
    tindex = 1
    max_paths = 0
    paths = Matrix(undef, nflows, nflows)
    for row in 1:size(x,1)
        if "->" in x[row,:]
            max_paths = max(max_paths, size(tf, 1))
            if fromNode != 0 && num_flow != 0
                #add tunnel if not first run
                paths[fromNode, toNode] = tf
                Tf[num_flow] = tf
            end
            if x[row,1] isa Number
                fromNode = x[row, 1] + zeroindex
                toNode = x[row, 3] + zeroindex
            else
                fromNode = parse(Int, replace(x[row, 1], "h" => "")) + zeroindex
                toNode = parse(Int, replace(x[row, 3], "h" => "")) + zeroindex
            end
            num_flow = findfirst(x -> x == (fromNode, toNode), flows)
            if num_flow == nothing
                num_flow = 0
            end
            tf = []
        else
            t = []
            #parse each tunnel into edges
            for col in 2:size(x,2)
                if occursin("]", x[row,col])
                    break
                end
                r = replace(x[row,col][2:end-2], "s" => "")
                stringtup = split(r, ",")
                #find edge in edge matrix
                e = (parse(Int,stringtup[1]) + zeroindex, parse(Int,stringtup[2]) + zeroindex)
                index = findfirst(x -> x == e, links)
                push!(t, index)
            end
            #create new tunnel and add index to that flows tunnels
            if num_flow != 0
                push!(T, t)
                push!(tf, tindex)
                tindex += 1
            end
        end
    end

    #add last tunnel
    if num_flow != 0
        Tf[num_flow] = tf
        paths[fromNode, toNode] = tf
    end
    push!(T, [])

    for f in 1:size(Tf,1)
        for t in 1:max_paths
            try Tf[f][t]
            catch
                push!(Tf[f], tindex)
            end
        end
    end
    return T, Tf, max_paths
end



####################################################################################
################################  Parse Matrix  ####################################
####################################################################################

function ParseMatrix(filename, num_nodes, num_demand)
    ignore = ()
    start_range = 0
    end_range = Inf
    x = readdlm(filename)[num_demand,:]
    m = zeros(length(x)-Int(sqrt(length(x))), 3)
    fromNode = 0
    count = 1
    for i in 0:(num_nodes^2-1)
        toNode = i%num_nodes + 1
        if toNode == 1
            fromNode += 1
        end
        if (fromNode != toNode && i >= start_range && i < end_range && !(fromNode in ignore) && !(toNode in ignore))
            m[count,1] = fromNode
            m[count,2] = toNode
            m[count,3] = x[i+1]
            count += 1
        end
    end
    ret = m
    for row in size(m,1):-1:1
        if (m[row,3] == 0)
            ret = ret[setdiff(1:end, row), :]
        end
    end
    return ret
end


####################################################################################
################################  KSP Tunnels  #####################################
####################################################################################


function getTunnels(nodes, edges, capacity, flows, k; edge_disjoint=false)
    num_edges = length(edges)
    num_nodes = length(nodes)
    num_flows = length(flows)
    graph = LightGraphs.DiGraph(num_nodes)
    distances = Inf*ones(num_nodes, num_nodes)

    for i in 1:num_edges
        LightGraphs.add_edge!(graph, edges[i][1], edges[i][2])
        distances[edges[i][1], edges[i][2]] = 1
        distances[edges[i][2], edges[i][1]] = 1
    end
    T = [[]]
    Tf = []
    ti = 2
    max_k = 1
    for f in 1:num_flows
        tf = []
        curr_k = 0
        state = LightGraphs.yen_k_shortest_paths(graph, flows[f][1], flows[f][2], distances, k)
        paths = state.paths
        edges_used = []
        for i in 1:k
            t = []
            path = i <= size(paths,1) ? paths[i] : []
            for n in 2:size(path,1)
                e = findfirst(x -> x == (path[n-1],path[n]), edges)
                push!(t, e)
            end
            if length(t) == 0 break end
            add = true
            for e in t
                if e in edges_used && edge_disjoint
                    add = false
                    break
                end
            end
            if add
                if edge_disjoint edges_used = vcat(edges_used, t) end
                push!(T, t)
                push!(tf, ti)
                ti += 1
                curr_k += 1
            end
        end
        max_k = max(max_k, curr_k)
        push!(Tf, tf)
    end

    for f in 1:num_flows
        for i in 1:max_k-length(Tf[f])
            push!(Tf[f], 1)
        end
    end
    return T, Tf, max_k, graph
end
