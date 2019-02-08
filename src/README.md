# RCPSP

A WIP resource constrained project scheduling program.

## Installation
In Julia v1.0 (and v0.7) you can install RCPSP from the Pkg REPL:
```
pkg> add https://github.com/mohamed82008/RCPSP.jl.git
```
which will track the `master` branch of the package.

## Example

Loading the package:
```julia
julia> using RCPSP
```

Generating a random project:
```julia
julia> project = rand(Project, 5)
Project{SparseArrays.SparseMatrixCSC{Bool,Int64},Array{Float64,1},Array{Float64,2},Array{Float64,1},CriticalPathInfo{Array{Float64,1},Array{Float64,1},SparseArrays.SparseMatrixCSC{Bool,Int64}}}
  n: Int64 5
  deps: SparseArrays.SparseMatrixCSC{Bool,Int64}
  durations: Array{Float64}((5,)) [2.9687, 0.8845, 1.7679, 1.7191, 0.2166]
  res: Array{Float64}((3, 5)) [0.88236 0.573851 … 0.261158 0.258086; 0.244779 0.361112 … 0.817759 0.299416; 0.737789 0.673291 … 0.874094 0.7098]
  res_lim: Array{Float64}((3,)) [1.0, 1.0, 1.0]
  info: CriticalPathInfo{Array{Float64,1},Array{Float64,1},SparseArrays.SparseMatrixCSC{Bool,Int64}}
```

Querying some information about the project:
```julia
julia> project.deps # adjacency matrix
5×5 SparseArrays.SparseMatrixCSC{Bool,Int64} with 4 stored entries:
  [2, 3]  =  true
  [2, 4]  =  true
  [3, 4]  =  true
  [2, 5]  =  true

julia> project.info.ES # earliest start times
5-element Array{Float64,1}:
 0.0
 0.0
 0.8845
 2.6524
 0.8845

julia> project.info.LS # latest start times
5-element Array{Float64,1}:
 1.4028
 1.1102230246251565e-16
 0.8845000000000001
 2.6524
 4.1549000000000005

julia> project.info.critical # critical path(s)
5×5 SparseArrays.SparseMatrixCSC{Bool,Int64} with 3 stored entries:
  [2, 3]  =  true
  [2, 4]  =  true
  [3, 4]  =  true
```

## Author

Mohamed Tarek - mohamed82008@gmail.com
