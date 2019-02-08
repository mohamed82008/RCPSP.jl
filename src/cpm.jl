@with_kw struct CriticalPathInfo{Tstart, Tfinish, Tcritical}
    ES::Tstart
    LS::Tstart
    EF::Tfinish
    LF::Tfinish
    critical::Tcritical
end

function CriticalPathInfo(project::Project{<:SparseMatrixCSC})
    @unpack n, deps, durations = project
    return _critical_path_info(n, deps, durations)
end
function _critical_path_info(n, deps::SparseMatrixCSC, durations)
    T = eltype(durations)
    deps_t = copy(deps')

    ES = zeros(T, n)
    LS = zeros(T, n)
    EF = zeros(T, n)
    LF = zeros(T, n)

    g = DiGraph(deps)
    cols = topological_sort_by_dfs(g)
    for col in cols
        inds = deps.colptr[col]:deps.colptr[col+1]-1
        if length(inds) == 0
            ES[col] = zero(T)
        else
            ES[col] = maximum(EF[deps.rowval[ind]] for ind in inds)
        end
        EF[col] = ES[col] + durations[col]
    end

    span = maximum(EF)
    
    g = DiGraph(deps_t)
    cols = topological_sort_by_dfs(g)
    for col in cols
        inds = deps_t.colptr[col]:deps_t.colptr[col+1]-1
        if length(inds) == 0
            LF[col] = span
        else
            LF[col] = minimum(LS[deps_t.rowval[ind]] for ind in inds)
        end
        LS[col] = max(LF[col] - durations[col], zero(T))
    end

    critical = copy(deps)
    for col in cols
        if ~(isapprox(ES[col], LS[col], atol = sqrt(eps(T))))
            critical[:, col] .= 0
        end
    end
    dropzeros!(critical)
    critical = copy(critical')
    for col in cols
        if ~(isapprox(ES[col], LS[col], atol = sqrt(eps(T))))
            critical[:, col] .= 0
        end
    end
    dropzeros!(critical)
    critical = copy(critical')

    return CriticalPathInfo(ES, LS, EF, LF, critical)
end
