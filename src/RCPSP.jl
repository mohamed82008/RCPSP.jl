module RCPSP

using SparseArrays, Parameters, JuMP, LightGraphs

export  Project, 
        Schedule,
        CriticalPathInfo

@with_kw struct Project{Tdeps, Tdurations, Tres, Tlim, Tinfo}
    n::Int
    deps::Tdeps
    durations::Tdurations
    res::Tres
    res_lim::Tlim
    info::Tinfo
end

struct Schedule{Ttimes}
    times::Ttimes
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
    res = rand(k, n)
    res_lim = fill(1.0, k)

    info = _critical_path_info(n, deps, durations)
    return Project(n, deps, durations, res, res_lim, info)
end

include("cpm.jl")

end # module
