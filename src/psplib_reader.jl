function get_resource(file, type)
    pattern = Regex("-\\s+$type\\s+:\\s+(\\d+)\\s+([a-zA-Z]+)")
    line = readline(file)
    m = match(pattern, line)
    n_resource = parse(Int, m.captures[1])
    sym_resource = m.captures[2]
    return n_resource, sym_resource
end

function read_project(i::Int = 30, k::String = "1_1")
    return read_project(joinpath(PROJECTS_DIR, string(i), "j$i$k.sm"))
end

function get_resource_metainfo(file)
    pattern = r"RESOURCES"
    line = readline(file)
    @assert match(pattern, line) !== nothing
    n_renewable, sym_renewable = get_resource(file, "renewable")
    n_nonrenewable, sym_nonrenewable = get_resource(file, "nonrenewable")
    n_doublyconstr, sym_doublyconstr = get_resource(file, "doubly constrained")

    return n_renewable, sym_renewable, n_nonrenewable, sym_nonrenewable,
            n_doublyconstr, sym_doublyconstr
end
function get_project_metainfo(line)
    pattern = r"\d+\s+\d+\s+\d+\s+(\d+)\s+(\d+)\s+\d+"
    m = match(pattern, line)
    due_date, tardiness_cost = m.captures
    return due_date, tardiness_cost
end
function get_jobs(file)
    jobs = []
    line = readline(file)
    pattern = r"(\d+)\s*(\d+)\s*(\d+)\s*([\d+\s*]*)"
    while !(occursin("*"^10, line))
        m = match(pattern, line)
        job_idx = parse(Int, m.captures[1])
        nmodes = parse(Int, m.captures[2])
        @assert nmodes == 1
        nsuccessors = parse(Int, m.captures[3])
        successors_string = m.captures[4]
        successors = [parse(Int, m.captures[1]) for m in eachmatch(r"(\d+)\s*", successors_string)]
        @assert length(successors) == nsuccessors
        push!(jobs, [job_idx, nmodes, nsuccessors, successors])
        line = readline(file)
    end
    return jobs
end
function get_resource_inds(line, sym_renewable, sym_nonrenewable, sym_doublyconstr)
    pattern = Regex("jobnr\\. mode duration\\s+([$sym_renewable\\s\\d+]*)([$sym_nonrenewable\\s\\d+\\s*]*)([$sym_doublyconstr\\s\\d+\\s*]*)")
    
    m = match(pattern, line)

    r_inds_string = m.captures[1]
    r_inds = [parse(Int, m.captures[1]) for m in eachmatch(r"(\d+)\s*", r_inds_string)]

    n_inds_string = m.captures[2]
    n_inds = [parse(Int, m.captures[1]) for m in eachmatch(r"(\d+)\s*", n_inds_string)]

    d_inds_string = m.captures[3]
    d_inds = [parse(Int, m.captures[1]) for m in eachmatch(r"(\d+)\s*", d_inds_string)]

    return r_inds, n_inds, d_inds
end

function update_jobs!(jobs, file, r_maxind, n_maxind, d_maxind)
    pattern = r"(\d+)\s*(\d+)\s*(\d+)\s*([\d+\s*]*)"
    line = readline(file)
    while !(occursin("*"^10, line))
        m = match(pattern, line)
        job_idx = parse(Int, m.captures[1])
        mode = parse(Int, m.captures[2])
        @assert mode <= jobs[job_idx][2]
        duration = parse(Int, m.captures[3])
        
        resources_string = m.captures[4]
        
        r_resources = fill(-1, r_maxind)
        n_resources = fill(-1, n_maxind)
        d_resources = fill(-1, d_maxind)

        for (i, m) in enumerate(eachmatch(r"(\d+)\s*", resources_string))
            if i <= r_maxind
                r_resources[i] = parse(Int, m.captures[1])
            elseif i <= r_maxind + n_maxind
                n_resources[i - r_maxind] = parse(Int, m.captures[1])
            elseif i <= r_maxind + n_maxind + d_maxind
                d_resources[i - r_maxind - n_maxind] = parse(Int, m.captures[1])
            end
        end
        @assert r_maxind == 0 || all(x -> x >= 0, r_resources)
        @assert n_maxind == 0 || all(x -> x >= 0, n_resources)
        @assert d_maxind == 0 || all(x -> x >= 0, d_resources)

        push!(jobs[job_idx], [mode, duration, r_resources, n_resources, d_resources])
        line = readline(file)
    end
    jobs
end
function get_resource_limits(line, r_maxind, n_maxind, d_maxind)
    r_resource_limits = fill(-1, r_maxind)
    n_resource_limits = fill(-1, n_maxind)
    d_resource_limits = fill(-1, d_maxind)
    for (i, m) in enumerate(eachmatch(r"(\d+)\s*", line))
        if i <= r_maxind
            r_resource_limits[i] = parse(Int, m.captures[1])
        elseif i <= r_maxind + n_maxind
            n_resource_limits[i - r_maxind] = parse(Int, m.captures[1])
        elseif i <= r_maxind + n_maxind + d_maxind
            d_resource_limits[i - r_maxind - n_maxind] = parse(Int, m.captures[1])
        end
    end
    @assert r_maxind == 0 || all(x -> x >= 0, r_resource_limits)
    @assert n_maxind == 0 || all(x -> x >= 0, n_resource_limits)
    @assert d_maxind == 0 || all(x -> x >= 0, d_resource_limits)

    return r_resource_limits, n_resource_limits, d_resource_limits
end

function read_project(filepath_with_ext::String)
    file = open(filepath_with_ext, "r")
    for i in 1:7
        line = readline(file)
    end
    n_renewable, sym_renewable, n_nonrenewable, sym_nonrenewable, 
        n_doublyconstr, sym_doublyconstr = get_resource_metainfo(file)

    for i in 1:4
        line = readline(file)
    end
    due_date, tardiness_cost = get_project_metainfo(line)

    for i in 1:3
        line = readline(file)
    end
    _jobs = get_jobs(file)

    for i in 1:2
        line = readline(file)
    end
    r_inds, n_inds, d_inds = get_resource_inds(line, sym_renewable, sym_nonrenewable, sym_doublyconstr)
    r_maxind = length(r_inds) == 0 ? 0 : maximum(r_inds)
    n_maxind = length(n_inds) == 0 ? 0 : maximum(n_inds)
    d_maxind = length(d_inds) == 0 ? 0 : maximum(d_inds)

    line = readline(file)
    jobs = update_jobs!(_jobs, file, r_maxind, n_maxind, d_maxind)

    for i in 1:3
        line = readline(file)
    end
    r_resource_limits, n_resource_limits, d_resource_limits = 
        get_resource_limits(line, r_maxind, n_maxind, d_maxind)

    close(file)

    res_lim = Resources(Tuple(r_resource_limits), Tuple(n_resource_limits), Tuple(d_resource_limits))

    sort!(_jobs, by = x->x[1])
    @assert all(_jobs[i][1] == i for i in 1:length(_jobs))
    jobs = map(_jobs) do _job
        modes = [Mode(m[2], Resources(Tuple.(m[3:end])...)) for m in _job[5:end]]
        Job(modes)
    end

    N = sum(length(job[4]) for job in _jobs)
    I = Int[]
    J = Int[]
    sizehint!(I, N)
    sizehint!(J, N)
    V = fill(true, N)
    for j in 1:length(_jobs)
        succ = _jobs[j][4]
        for i in succ
            push!(I, i)
            push!(J, j)
        end
    end
    n = length(jobs)
    deps = sparse(I, J, V, n, n)

    if all(length(job.modes) == 1 for job in jobs)
        durations = [job.modes[1].duration for job in jobs]
        info = _critical_path_info(n, deps, durations)
    else
        info = nothing
    end

    return Project(jobs, deps, res_lim, info)
end
