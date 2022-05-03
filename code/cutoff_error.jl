import Pkg
Pkg.add("DelimitedFiles")
Pkg.add("ProgressMeter")
Pkg.add("PyPlot")

using DelimitedFiles, ProgressMeter, PyPlot

include("./util.jl")
include("./parsers.jl")
include("./Algorithms/TEAVAR.jl")
include("./simulation.jl")


function topologyCutoffError(
    topology,
    num_demands,
    iterations,
    cutoffs;
    paths = "SMORE",
    weibull_scale = 0.0001,
    demand_downscale = 5000,
    plot = true,
    dirname = "./data/raw/cutoff_error/",
)
    env = Gurobi.Env()
    y_vals = []
    scenarios = []
    probs = []
    links, capacity, link_probs, nodes = readTopology("$(topology)")
    demand, flows = readDemand(
        "$(topology)/demand",
        length(nodes),
        1,
        scale = 1,
        downscale = demand_downscale,
    )
    T, Tf, k = parsePaths("$(topology)/paths/$(paths)", links, flows)

    dir = nextRun(dirname)
    for j = 1:length(cutoffs)
        writedlm("$(dir)/cutoff_$(cutoffs[j])_error", [["cvar_o", "cvar", "error_cvar"]])
    end

    progress = ProgressMeter.Progress(
        num_demands * iterations * length(cutoffs),
        0.1,
        "Computing cutoff error...",
        50,
    )
    cutoff_errors = zeros(length(cutoffs))
    for d = 1:num_demands
        demand, flows = readDemand(
            "$(topology)/demand",
            length(nodes),
            d,
            scale = 1,
            downscale = demand_downscale,
        )
        for i = 1:iterations
            weibull_probs =
                weibullProbs(length(link_probs), shape = 0.8, scale = weibull_scale)
            optimal_scenarios, optimal_probs = subScenarios(
                weibull_probs,
                (sum(weibull_probs) / length(weibull_probs))^2,
                first = true,
                last = true,
            )
            beta = optimal_probs[1]
            var_o, cvar_o, a_o, max_u_o = TEAVAR(
                env,
                links,
                capacity,
                flows,
                demand,
                beta,
                k,
                T,
                Tf,
                optimal_scenarios,
                optimal_probs,
            )
            for j = 1:length(cutoffs)
                scenarios, scenario_probs =
                    subScenarios(weibull_probs, cutoffs[j], first = true, last = true)
                var, cvar, a, max_u = TEAVAR(
                    env,
                    links,
                    capacity,
                    flows,
                    demand,
                    beta,
                    k,
                    T,
                    Tf,
                    scenarios,
                    scenario_probs,
                )
                cvar_o = sum((1 .- max_u_o) .* optimal_probs)
                cvar = sum((1 .- max_u) .* scenario_probs)
                err = abs((cvar_o - cvar) / cvar_o)
                cutoff_errors[j] += err
                open("$(dir)/cutoff_$(cutoffs[j])_error", "a") do io
                    writedlm(io, transpose([cvar_o, cvar, err]))
                end
                ProgressMeter.next!(
                    progress,
                    showvalues = [
                        (:topology, topology),
                        (:demand, "$(d)/$(num_demands)"),
                        (:iterations, "$(i)/$(iterations)"),
                        (:cutoff, cutoffs[j]),
                        (:error, err),
                    ],
                )
            end
        end
    end
    y_vals = cutoff_errors ./ (num_demands * iterations)
    writedlm("$(dir)/cutoffs", cutoffs)
    writedlm("$(dir)/y_vals", y_vals)
    writedlm(
        "$(dir)/params",
        [
            [
                "topology",
                "num_demands",
                "iterations",
                "cutoffs",
                "paths",
                "weibull_scale",
                "demand_downscale",
            ],
            [
                topology,
                num_demands,
                iterations,
                cutoffs,
                paths,
                weibull_scale,
                demand_downscale,
            ],
        ],
    )

    if plot
        PyPlot.clf()
        nbars = length(cutoffs)
        barWidth = 1 / (nbars)
        for i = 1:length(y_vals)
            PyPlot.bar(barWidth * i, y_vals[i], alpha = 0.8, width = barWidth)
        end
        PyPlot.ylabel("Percent Error", fontweight = "bold")
        PyPlot.legend(cutoffs, loc = "upper right")
        PyPlot.savefig("$(dir)/plot.png")
        PyPlot.show()
    end
end

# topologyCutoffError("B4", 2, 2, [.0001,.00001,.000001,.0000001], demand_downscale=5000)
