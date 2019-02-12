module RCPSP

const PROJECTS_DIR = abspath(joinpath(@__DIR__, "..", "projects"))

using SparseArrays, Parameters, LightGraphs, GLPK, Reexport, StructArrays
@reexport using JuMP

export  Project, 
        Schedule,
        CriticalPathInfo,
        Resources,
        OnOffEventModel

include("main_types.jl")
include("utils.jl")
include("cpm.jl")
include("on_off_formulation.jl")
include("psplib_reader.jl")

JuMP.optimize!(project::Project) = optimize!(OnOffEventModel(project))

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
    res_req = reinterpret(Resources{NTuple{k, Float64}, Tuple{}, Tuple{}}, rand(k*n))
    jobs = Job.((x->[x]).(Mode.(durations, res_req)))

    res_lim = Resources(ntuple(x->1.0, Val(k)), (), ())
    info = _critical_path_info(n, deps, durations)

    return Project(jobs, deps, res_lim, info)
end

end # module
