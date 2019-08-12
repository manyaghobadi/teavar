using LightGraphs, Compose, GraphPlot, Cairo, Fontconfig

include("./parsers.jl")
####################################################################################
####################  Draw graph with edges and allocations  #######################
####################################################################################

function drawGraph(a, L, Tf, edges, num_nodes)
    edgelabels = []
    graph = LightGraphs.DiGraph(num_nodes)
    for e in 1:size(edges,1)
        LightGraphs.add_edge!(graph, edges[e][1], edges[e][2])
        s = 0
        for f in 1:size(a,1)
            for t in 1:size(a,2)
                s += a[f,t] * L[Tf[f][t],e]
            end
        end
        push!(edgelabels, s)
    end
    nodelabel = collect(1:num_nodes)
    Compose.draw(PNG("./graph.png", 1000, 1000), gplot(graph, edgelabelc="white", EDGELABELSIZE = 15.0, NODELABELSIZE=20.0, nodelabel=nodelabel, edgelabeldisty=0.5, edgelabel=edgelabels, EDGELINEWIDTH=3.0, arrowlengthfrac=.04))
end


function drawGraph(topology; outdir="./")
    edges, capacity, probabilities, nodes = readTopology(topology)
    graph = LightGraphs.DiGraph(length(nodes))
    for e in 1:length(edges)
        LightGraphs.add_edge!(graph, edges[e][1], edges[e][2])
    end
    nodelabel = collect(1:length(nodes))
    Compose.draw(PNG("$(outdir)/graph.png", 1000, 1000), gplot(graph, edgelabelc="white", EDGELABELSIZE = 15.0, NODELABELSIZE=20.0, nodelabel=nodelabel, edgelabeldisty=0.5, EDGELINEWIDTH=3.0, arrowlengthfrac=.04))
end

