import Pkg
# Pkg.add("Conda")
# Pkg.add("PyPlot")
# Pkg.add("ProgressMeter")
# Pkg.add("Gurobi")
# Pkg.add("DataFrames")
# Pkg.add("JuMP")
# Pkg.add("Combinatorics")
# Pkg.add("LightGraphs")
# Pkg.add("DelimitedFiles")
# Pkg.add("MathProgBase")
# Pkg.add("GraphPlot")
# Pkg.add("Compose")
# Pkg.add("Cairo")
# Pkg.add("Fontconfig")
# Pkg.add("Distributions")
# Pkg.add("HTTP")
# Pkg.add("Sockets")
# Pkg.add("JSON2")
# Pkg.add("JSON")
# using Conda; Conda.add("pyqt")

using HTTP, Sockets, JSON2

include("./util.jl")
include("./parsers.jl")
include("./Algorithms/TEAVAR.jl")

mutable struct Request
    topology::String
    demand::String
    path::String
    beta::String
    cutoff::String
    k::String
    downscale_demand::String
end

mutable struct Response
    var::Float64
    cvar::Float64
    allocation::Array
    num_nodes::Int64
    capacity::Array
    failure_probabilities::Array
    flows::Array
    demand::Array
    T::Array
    Tf::Array
    links::Array
    scenarios::Array
    probabilities::Array
    X::Array
end

ROUTER = HTTP.Router()

function JSONHandler(req::HTTP.Request)
    if req.method == "OPTIONS"
        res = HTTP.Response(200)
        res.headers = [Pair("Access-Control-Allow-Origin", "*"),
                       Pair("Vary", "Origin"),
                       Pair("Vary", "Access-Control-Request-Method"),
                       Pair("Vary", "Access-Control-Request-Headers"),
                       Pair("Access-Control-Allow-Headers", "Content-Type, Origin, Accept, token"),
                       Pair("Access-Control-Allow-Methods", "GET, POST,OPTIONS")]
        return res
        response_body = HTTP.handle(ROUTER, req)
    else
        response_body = HTTP.handle(ROUTER, req)
    end
    res = HTTP.Response(200, JSON2.write(response_body))
    res.headers = [Pair("Access-Control-Allow-Origin", "*")]
    return res
end


function teavar(req::HTTP.Request)
    json = JSON2.read(IOBuffer(HTTP.payload(req)), Request)
    println(json)
    
    topology = json.topology
    demand_num = parse(Int64, json.demand)
    beta = parse(Float64, json.beta)
    cutoff = parse(Float64, json.cutoff)
    k = parse(Int64, json.k)
    downscale_demand = parse(Int64, json.downscale_demand)

    links, capacity, link_probs, nodes = readTopology(topology, downscale=1)
    weibull_probs = weibullProbs(length(links), shape=.8, scale=.001)
    scenarios, scenario_probs = subScenarios(weibull_probs, cutoff, first=true, last=false)
    # w_scenarios, w_probs = subScenarios(weibull_probs, cutoff, first=true, last=false)
    demand, flows = readDemand("$(topology)/demand", length(nodes), demand_num, scale=1.0, downscale=downscale_demand)

    T, Tf = [], []
    try
        T, Tf, k = parsePaths("$(topology)/paths/$(json.path)", links, flows)
    catch
        if json.path == "ED"
            T, Tf, k, g = getTunnels(nodes, links, capacity, flows, 30, edge_disjoint=true)
        else
            T, Tf, k, g = getTunnels(nodes, links, capacity, flows, k)
        end
    end
    # a = parseYatesSplittingRatios("$(topology)/paths/$(algorithm)", k, flows, zeroindex=zeroindex)
    # a = parseYatesAllocations("$(topology)/paths/$(algorithm)", k, demand, flows, zeroindex=zeroindex)

    env = Gurobi.Env()
    var, cvar, a = TEAVAR(env, links, capacity, flows, demand, beta, k, T, Tf, scenarios, scenario_probs)
    println(var)
    println(cvar)
    println(a)

    nscenarios = length(scenarios)
    ntunnels = length(T)
    X  = ones(nscenarios,ntunnels)
    for s in 1:nscenarios
        for t in 1:ntunnels
            if size(T[t],1) == 0
                X[s,t] = 0
            else
                for e in 1:length(links)
                    if scenarios[s][e] == 0
                        back_edge = findfirst(x -> x == (links[e][2],links[e][1]), links)
                        if in(e, T[t]) || in(back_edge, T[t])
                            X[s,t] = 0
                        end
                    end
                end
            end
        end
    end
    http_res = Response(var, cvar, [a[i, :] for i in 1:size(a, 1)], length(nodes), capacity, weibull_probs, flows, demand, T, Tf, links, scenarios, scenario_probs, [X[i, :] for i in 1:size(X, 1)])
    return http_res
end


function main()
    println("Listening on localhost:8080....")
    HTTP.@register(ROUTER, "POST", "/api/teavar", teavar)
    HTTP.serve(JSONHandler, Sockets.localhost, 8080)
end

main()
