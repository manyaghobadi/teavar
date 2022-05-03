using ArgParse

include("./POP.jl")


function parseArgs()
    s = ArgParseSettings()
    @add_arg_table s begin
        "--num-subproblems-range", "-n"
        help = "number of sub problems to run POP with"
        arg_type = String
        required = true
        "--split-fraction", "-s"
        help = "fraction of additional commodities to split"
        arg_type = Float64
        default = 0.0
        range_tester = (x) -> x >= 0.0
        "--topology", "-t"
        help = "Topology to run with"
        arg_type = String
        required = true
        range_tester = (x) -> x == "B4" || x == "IBM" || x == "XNet" || x == "ATT"
    end
    return parse_args(s)
end

function runPOP()
    parsed_args = parseArgs()
    topology = parsed_args["topology"]
    num_subproblems_range =
        map(i -> parse(Int, i), split(parsed_args["num-subproblems-range"], ","))
    benchmarkPOP(topology, num_subproblems_range = num_subproblems_range)
end

runPOP()
