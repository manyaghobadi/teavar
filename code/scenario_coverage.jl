using DelimitedFiles, ProgressMeter, PyPlot

include("./util.jl")
include("./parsers.jl")

function scenarioCoverage(topology,
                          iterations,
                          cutoffs; shape=.8,
                          scale=.0001,
                          weibull=true,
                          plot=true,
                          dirname="./data/raw/scenario_coverage")
    y_vals = []
    weibull_probs = []
    labels = []
    optimal_vals = []

    # COMUTE SCENARIOS
    links, capacity, link_probs, nodes = readTopology(topology)
    for j in 1:iterations
        if weibull
            probs = weibullProbs(length(link_probs), shape=shape, scale=scale)
        else
            probs = link_probs
        end
        push!(weibull_probs, probs)
        scenarios, probabilities = subScenariosRecursion(probs, sum(probs)/length(probs)^2)
        push!(optimal_vals, sum(probabilities))
    end

    # COMPUTE COVERAGE
    progress = ProgressMeter.Progress(length(cutoffs)*iterations, .1, "Computing Scenario Coverage...", 50)
    for i in 1:length(cutoffs)
        vals = []
        for j in 1:iterations
            scenarios, probabilities = subScenariosRecursion(weibull_probs[j], cutoffs[i])
            push!(vals, sum(probabilities))
            ProgressMeter.next!(progress, showvalues = [(:cutoff, cutoffs[i]), (:iteration, "$(j)/$(iterations)"), (:coverage, sum(probabilities))])
        end
        push!(y_vals, sum(vals)/length(vals))
        push!(labels, cutoffs[i])
    end
    push!(labels, "optimal")
    push!(y_vals, sum(optimal_vals)/length(optimal_vals))


    # LOG RESULTS
    dir = nextRun(dirname)
    writedlm("$(dir)/weibull_probs", weibull_probs)
    writedlm("$(dir)/coverage", y_vals)
    writedlm("$(dir)/cutoffs", labels)
    writedlm("$(dir)/params", [["iterations"], [iterations]])

    # PLOT
    if plot
        PyPlot.clf()
        nbars = length(labels)
        barWidth = 1/(nbars)
        for i in 1:length(y_vals)
            PyPlot.bar((barWidth .* i), y_vals[i], alpha=0.8, width=barWidth)
        end
        PyPlot.ylabel("Total Coverage", fontweight="bold")
        PyPlot.legend(labels, loc="lower right")
        PyPlot.savefig("$(dir)/plot.png")
        PyPlot.show()
    end
end

# scenarioCoverage("./Data/IBM", 100, [.001,.0001,.00001,.000001,.0000001]; shape=.8, scale=.0001, weibull=true)


