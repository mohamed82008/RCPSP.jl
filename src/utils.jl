struct EdgeIterator{Tdeps}
    deps::Tdeps
end
Base.length(iter::EdgeIterator) = length(iter.deps.nzval)
function Base.iterate(edgeiter::EdgeIterator, state = (1, 1))
    col_state, ind_state = state
    @unpack colptr, rowval = edgeiter.deps
    for col in col_state:length(colptr)-1
        inds = max(ind_state, colptr[col]):colptr[col+1]-1
        for ind in inds
            return (rowval[ind], col), (col, ind+1)
        end
    end
    return nothing
end

function compress!(soa)
    k = 0
    i = 1
    while i <= length(soa)
        if i < length(soa) && isapprox(soa[i][1], soa[i+1][1], atol = 1e-4)
            k += 1
            soa[k] = (soa[i][1], soa[i][2] + soa[i+1][2])
            i += 2
        else
            k += 1
            soa[k] = soa[i]
            i += 1
        end
    end
    resize!(soa, k)
    return soa
end

function ResourcesTrace(project::Project, schedule::Schedule; compress = true)
    @unpack start_times = schedule
    @unpack res_req, res_lim, durations, n = project
    Tr = eltype(res_req)
    Tt = eltype(start_times)

    time_stamps = Tt[]
    res_changes = Tr[]
    sizehint!(time_stamps, 2*n)
    sizehint!(res_changes, 2*n)
    for i in 1:n
        push!(time_stamps, start_times[i])
        push!(res_changes, res_req[i])
        push!(time_stamps, start_times[i] + durations[i])
        push!(res_changes, -(res_req[i]))
    end
    soa = StructArray((time_stamps, res_changes))
    sort!(soa, by=x->x[1])
    if compress
        compress!(soa)
    end
    accumulate!((x,y)->(y[1], x[2]+y[2]), soa, soa, dims = 1)
    res_changes .= Ref(res_lim) .- res_changes

    return ResourcesTrace(time_stamps, res_changes)
end
