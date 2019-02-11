module RCPSP

const PROJECTS_DIR = joinpath(@__DIR__, "projects")

using SparseArrays, Parameters, LightGraphs, GLPK, Reexport, StructArrays
@reexport using JuMP

export  Project, 
        Schedule,
        CriticalPathInfo,
        Resources

@with_kw struct Project{Tdeps, Tdurations, Tres, Tlim, Tinfo}
    n::Int
    deps::Tdeps
    durations::Tdurations
    res_req::Tres
    res_lim::Tlim
    info::Tinfo
end
struct Schedule{Ttimes}
    start_times::Ttimes
end

function Base.rand(::Type{<:Project}, n::Int = 10, mean_deps::Int = max(2, n ÷ 10); k = 3)
    p = mean_deps / n
    deps = sprand(Bool, n, n, p)
    for col in 1:length(deps.colptr)-1
        inds = deps.colptr[col]:deps.colptr[col+1]-1
        for ind in inds
            row = deps.rowval[ind]
            if col <= row
                deps.nzval[ind] = 0
            end
        end
    end
    dropzeros!(deps)
    durations = round.(rand(n) .* 3 .+ 0.1, digits=4)
    res_req = reinterpret(Resources{k, NTuple{k, Float64}}, rand(k*n))
    res_lim = Resources(ntuple(x->1.0, Val(k)))

    info = _critical_path_info(n, deps, durations)
    return Project(n, deps, durations, res_req, res_lim, info)
end

include("utils.jl")
include("cpm.jl")
include("on_off_formulation.jl")

end # module
