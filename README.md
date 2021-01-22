<img src="www/img/logo.png" alt="teavar logo" style="float: left; margin-right: 10px;" /><br/><br/><br/><br/><br/><br/>
## [Traffic Engineering Applying Value at Risk](http://teavar.csail.mit.edu)

TEAVAR is a traffic engineering scheme that balances utilization and availability to provide bandwidth guarantees at a desired SLA. This codebase also includes a simulation framework that was used to test TEAVAR, as well as implementations of other traffice engineering algorithms in Julia.
## Getting started

### Installation: 
**Quick start:**

1. Install [Julia](https://julialang.org/)

2. Install open a julia shell using:
    ```
    julia
    ```

3. Install [JuMP](https://github.com/JuliaOpt/JuMP.jl) version v0.18.5 using the Julia REPL:
    ```
    julia> ]
    (v1.0) pkg>add JuMP@0.18.5 
    ```
  
4. Include certain files using:
    ```
    include("./main.jl")
    ```

main.jl is the main entrypoint but you can also include specific files invidually to run specific experiments

Note: Most TE algorithms in this codebase are implemented as Linear Programs and require the [Gurobi](http://www.gurobi.com/) solver.


**Using Pre-built binaries:**

Instead of installing Julia and using the Julia REPL to run different files, we have compiled the codebase into binaries available on [Mac](http://teavar.csail.mit.edu/builds/osxbuild.zip) and [Linux](http://teavar.csail.mit.edu/builds/linuxbuild.tar.gz). To install these go to our homepage or follow the links above.

1. Install the binary for your operating system

2. Unzip the file
```
tar -xvf linuxbuild.tar.gz
```

3. Run the file teavar. Add -help or -h for more information on accepted parameters
```
./teavar -help
```

## Outline:

**Data:**
All data used for TEAVAR evaluations is in the data folder. Each folder contains a topology. A topology must include 3 files.

1. nodes.txt
    A list of string nodenames
2. topology.txt
    A list of rows containing edges with a source, destination, capacity, and probability of failure. 
3. demand.txt
    A set of demands in matrix form or list form. (See data/Custom/demand.txt for list form)

**Results:**
Results from experiments are saved in data/raw. Each experiment has its own folder in data/raw that contains a counter and saves each experiment run results in a folder with the counter number. Results used in the paper have been moved from data/raw to gnuplot/data. 

**Plots:**
Data for plots used in TEAVAR can be found in the gnuplot/data folder. All plotting code is also in gnuplot folder (gnuplot/*.gp) and each plotting file outputs plots to gnuplot/plots.

Gnuplot can be installed on OSX using homebrew (```brew install gnuplot```) or linux using apt (```apt get gnuplot```). More information on gnuplot can be [found on the gnuplot website](http://www.gnuplot.info/).

**TE Schemes:**
All TE schemes (mostly case as linear programs) can be found by name in the Algorithms folder.


## Credits
See the [list contributors](http://teavar.csail.mit.edu).
