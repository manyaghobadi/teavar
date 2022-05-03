#! /usr/bin/env bash

set -e
set -x

julia run_pop.jl -t B4 -n 1 &> 1-subproblem.txt
julia run_pop.jl -t B4 -n 2 &> 2-subproblems.txt
julia run_pop.jl -t B4 -n 4 &> 4-subproblems.txt
julia run_pop.jl -t B4 -n 8 &> 8-subproblems.txt

