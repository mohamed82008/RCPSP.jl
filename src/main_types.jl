struct Resources{Tr, Tn, Td}
    renewable::Tr
    nonrenewable::Tn
    doublyconstr::Td
end
Base.length(r::Resources{<:Any, Tuple{}, Tuple{}}) = length(r.r)
Base.length(r::Resources{Tuple{}, <:Any, Tuple{}}) = length(r.n)
Base.length(r::Resources{Tuple{}, Tuple{}, <:Any}) = length(r.d)
Base.length(r::Resources{Tuple{}, Tuple{}, Tuple{}}) = 0

Base.getindex(r::Resources{<:Any, Tuple{}, Tuple{}}, i...) = r.r[i...]
Base.getindex(r::Resources{Tuple{}, <:Any, Tuple{}}, i...) = r.n[i...]
Base.getindex(r::Resources{Tuple{}, Tuple{}, <:Any}, i...) = r.d[i...]
Base.getindex(r::Resources{Tuple{}, Tuple{}, Tuple{}}, i...) = r.r[i...]

function Base.getproperty(r::Resources, f::Symbol)
    f === :r && return getfield(r, :renewable)
    f === :n && return getfield(r, :nonrenewable)
    f === :d && return getfield(r, :doublyconstr)
    return getfield(r, f)
end
function Base.getindex(r::Resources, f::Symbol, i...)
    (f === :renewable || f === :r) && return r.r[i...]
    (f === :nonrenewable || f === :n) && return r.n[i...]
    (f === :doublyconstr || f === :d) && return r.d[i...]
    throw("$r not defined.")
end

for op in (:+, :-)
    @eval Base.$op(r1::Resources, r2::Resources) = Resources($op.(r1.r, r2.r), $op.(r1.n, r2.n), $op.(r1.d, r2.d))
end
Base.:-(r::Resources) = Resources(.-(r.r), .-(r.n), .-(r.d))

for op in (:*, :/)
    @eval Base.$op(r1::Real, r2::Resources) = Resources($op.(r1, r2.r), $op.(r1, r2.n), $op.(r1, r2.d))
end

struct ResourcesTrace{Ttime, Tres}
    time_stamps::Ttime
    resources::Tres
end

struct Mode{Tt, Tr <: Resources}
    duration::Tt
    res::Tr
end
struct Job{Tm <: Mode}
    modes::Vector{Tm}
end

@with_kw struct Project{TJ <: Job, Tdeps, Tlim, Tinfo}
    jobs::Vector{TJ}
    deps::Tdeps
    res_lim::Tlim
    info::Tinfo
end
function issinglemode(project::Project)
    all(getnmodes(project, i) == 1 for i in getnjobs(project))
end

function Base.getproperty(project::Project, f::Symbol)
    if f === :durations
        @assert issinglemode(project)
        jobs = getfield(project, :jobs)
        return [job.modes[1].duration for job in jobs]
    elseif f === :res_req
        @assert issinglemode(project)
        jobs = getfield(project, :jobs)
        return [job.modes[1].res for job in jobs]
    elseif f === :n
        return length(project.jobs)
    end
    return getfield(project, f)
end
getnmodes(p::Project, j::Int) = length(p.jobs[j].modes)
getnjobs(p::Project) = length(p.jobs)


struct ModesOf{Tp <: Project}
    project::Tp
end
Base.getindex(p::ModesOf, i::Int, j::Int=1) = p.jobs[i].modes[j]

struct Schedule{Ttimes}
    start_times::Ttimes
end
