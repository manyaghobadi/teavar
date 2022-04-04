import Pkg
Pkg.add("ArgParse")
using ArgParse

include("./POP.jl")


function parseArgs()
    s = ArgParseSettings()
    @add_arg_table s begin
        "--num-subproblems", "-n"
            help = "number of sub problems to run POP with"
            arg_type = Int
            required = true
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
    num_subproblems = parsed_args["num-subproblems"]
    benchmarkPOP(topology, num_subproblems=num_subproblems)
end

runPOP()