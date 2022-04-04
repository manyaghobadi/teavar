import Pkg
Pkg.add("ArgParse")
using ArgParse

include("./scenario_coverage.jl")
include("./throughput_guarantee.jl")
include("./availability.jl")
include("./cutoff_error.jl")
include("./path_selection.jl")
include("probability_noise.jl")
include("./network_utilization.jl")
include("throughput.jl")
include("./timer.jl")

function readInput(message, default, type)
    print(message)
    try
        if type == String
            res = readline()
            return length(res) > 0 ? res : default
        else
            return parse(type, readline())
        end
    catch
        return default
    end
end

function parse_commandline()
    s = ArgParseSettings()
    @add_arg_table s begin
        "experiment"
            help = "Type of experiment to run. One of...
                            scenarios_coverage (Fig 12a)
                            optimizer_times (Fig 12c)
                            throughput_guarantee (Fig 10)
                            availability (Fig 7)
                            cutoff_error (Fig 12b)
                            path_selection (Fig 11)
                            probability_noise (Table 3)
                            throughput (Fig 9)
                            utilization"
        "--plot", "-p"
            help = "Boolean whether or not to plot the results of the given experiment"
            action = :store_true
    end

    return parse_args(s)
end

Base.@ccallable function julia_main()::String
    parsed_args = parse_commandline()

    println("Asking for inputs. Press enter for default values\n")

    experiment = parsed_args["experiment"] !=  nothing ? parsed_args["experiment"] : readInput("Experiment (scenario_coverage): ", "scenario_coverage", String)
    plot = parsed_args["plot"] || readInput("Plot results? (true): ", true, Bool)

    println("\nRunning experiment [", experiment, "] with plotting [", plot, "]...")
    if experiment == "scenario_coverage"
        shape = readInput("Weibull shape (0.8): ", 0.8, Float64)
        scale = readInput("Weibull scale (0.0001): ", 0.0001, Float64)
        topology = readInput("Topology (B4): ", "B4", String)
        cutoffs = map(i -> parse(Float64, i), split(readInput("Cutoffs (.001,.0001,.00001,.000001,.0000001): ", ".001,.0001,.00001,.000001,.0000001", String), ","))
        iterations = readInput("Iterations (100): ", 100, Int)
        scenarioCoverage("$topology", iterations, cutoffs; shape=shape, scale=scale, weibull=true, plot=plot)
    elseif experiment == "optimizer_times"
        topologies = split(readInput("Topologies (B4,IBM,XNet,ATT): ", "B4,IBM,XNet,ATT", String), ",")
        cutoffs = map(i -> parse(Float64, i), split(readInput("Cutoffs (.001,.0001,.00001,.000001): ", ".001,.0001,.00001,.000001", String), ","))
        iterations = readInput("Iterations (100): ", 100, Int)
        timeOptimizer(topologies, cutoffs, iterations, plot=plot)
    elseif experiment == "throughput_guarantee"
        topologies = split(readInput("Topologies (B4,IBM): ", "B4,IBM", String), ",")
        availabilities = map(i -> parse(Float64, i), split(readInput("Availabilities (.99, .999, .9999, .99995, .99999): ", ".99, .999, .9999, .99995, .99999", String), ","))
        cutoff = readInput("Cutoff (0.00000003): ", 0.00000003, Float64)
        num_demands = readInput("Number of demands (2): ", 2, Int)
        iterations = readInput("Iterations (2): ", 2, Int)
        getThroughputGuarantees(availabilities, cutoff, topologies, num_demands, iterations, plot=plot)
    elseif experiment == "availability"
        topologies = split(readInput("Topologies (IBM): ", "IBM", String), ",")
        algorithms = split(readInput("Algorithms (TEAVAR,SMORE,ECMP,FFC-1): ", "TEAVAR,SMORE,ECMP,FFC-1", String), ",")
        cutoff = readInput("Cutoff (0.0001): ", 0.0001, Float64)
        weibull_scale = readInput("Weibull scale (0.001): ", 0.001, Float64)
        num_demands = readInput("Number of demands (10): ", 10, Int)
        iterations = readInput("Iterations (10): ", 10, Int)
        demand_downscales = map(i -> parse(Float64, i), split(readInput("Demand downscales (2): ", "2", String), ","))
        start = readInput("Start (1): ", 1, Float64)
        step = readInput("Step (0.1): ", 0.1, Float64)
        finish = readInput("Finish (4.0): ", 4, Float64)
        # paths = readInput("Paths (SMORE): ", "SMORE", String)
        availabilityPlot(algorithms, topologies, demand_downscales, num_demands, iterations, cutoff, start, step, finish, weibull_scale=weibull_scale, paths="KSP", k=12, plot=plot)
    elseif experiment == "cutoff_error"
        topology = readInput("Topology (B4): ", "B4", String)
        cutoffs = map(i -> parse(Float64, i), split(readInput("Cutoffs (.0001,.00001,.000001,.0000001): ", ".0001,.00001,.000001,.0000001", String), ","))
        num_demands = readInput("Number of demands (10): ", 10, Int)
        iterations = readInput("Iterations (10): ", 10, Int)
        weibull_scale = readInput("Weibull scale (0.0001): ", 0.0001, Float64)
        # demand_downscale = readInput("Demand downscale (0.5): ", 0.5, Float64)
        topologyCutoffError(topology, num_demands, iterations, cutoffs, demand_downscale=1.0, weibull_scale=weibull_scale)
    elseif experiment == "path_selection"
        topologies = split(readInput("Topologies (B4,IBM): ", "B4,IBM", String), ",")
        demand_downscales = map(i -> parse(Float64, i), split(readInput("Demand downscales (4000,4000): ", "4000,4000", String), ","))
        availabilities = map(i -> parse(Float64, i), split(readInput("Availabilities (.9,.92,.94,.96,.98,.99): ", ".9,.92,.94,.96,.98,.99", String), ","))
        cutoff = readInput("Cutoff (0.001): ", 0.0001, Float64)
        num_demands = readInput("Number of demands (6): ", 6, Int)
        ksp = map(i -> parse(Int, i), split(readInput("KSP (4,6): ", "4,6", String), ","))
        paths = split(readInput("Paths (SMORE,FFC): ", "SMORE,FFC", String), ",")
        pathSelection(topologies, demand_downscales, paths, num_demands, availabilities, cutoff, ksp=ksp, plot=plot)
    elseif experiment == "probability_noise"
        topologies = split(readInput("Topologies (B4): ", "B4", String), ",")
        demand_downscales = map(i -> parse(Float64, i), split(readInput("Demand downscales (1): ", "1", String), ","))
        cutoff = readInput("Cutoff (0.00001): ", 0.00001, Float64)
        num_demands = readInput("Number of demands (2): ", 2, Int)
        iterations = readInput("Iterations (20): ", 20, Int)
        noises = map(i -> parse(Float64, i), split(readInput("Noises (.01,.05,.1,.15,.2): ", ".01,.05,.1,.15,.2", String), ","))
        probabilityNoise(topologies, demand_downscales, num_demands, iterations, cutoff, noises, paths="SMORE", weibull_scale=.001, add_noise="EVENTS", plot=plot)
    elseif experiment == "throughput"
        topologies = split(readInput("Topologies (B4,ATT): ", "B4,ATT", String), ",")
        demand_downscales = map(i -> parse(Float64, i), split(readInput("Demand downscales (1,1): ", "1,1", String), ","))
        algorithms = split(readInput("Algorithms (TEAVAR,SMORE,ECMP,FFC): ", "TEAVAR,SMORE,ECMP,FFC", String), ",")
        availabilities = map(i -> parse(Float64, i), split(readInput("Availabilities (.9,.95,.99,.999,.9999): ", ".9,.95,.99,.999,.9999", String), ","))
        cutoff = readInput("Cutoff (0.00001): ", 0.00001, Float64)
        num_demands = readInput("Number of demands (4): ", 4, Int)
        iterations = readInput("Iterations (4): ", 4, Int)
        getThroughputGraphs(algorithms, topologies, demand_downscales, num_demands, iterations, availabilities, cutoff, teavar_paths="KSP", weibull_scale=.0001, plot=plot)
    elseif experiment == "utilization"
        topology = readInput("Topology (B4): ", "B4", String)
        availabilities = map(i -> parse(Float64, i), split(readInput("Availabilities (.99,.999,.9999): ", ".99,.999,.9999", String), ","))
        cutoff = readInput("Cutoff (0.00001): ", 0.00001, Float64)
        num_demands = readInput("Number of demands (3): ", 3, Int)
        iterations = readInput("Iterations (3): ", 3, Int)
        network_utilization(topology, 1, 1, num_demands, iterations, cutoff, availabilities, plot=plot)
    end
    return "...Complete"
end

julia_main()