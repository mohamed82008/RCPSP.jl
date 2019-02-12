# Single mode, renewable resources only for now
@with_kw struct OnOffEventModel{Tproject, Tmodel, Tvars}
    project::Tproject
    jump_model::Tmodel
    vars::Tvars
end

function OnOffEventModel(project::Project)
    n, durations, res_req = project.n, project.durations, project.res_req
    @unpack deps, res_lim, info = project
    Tt = eltype(durations)
    Tr = eltype(res_lim)
    span = info == nothing ? 1000 : maximum(info.EF)

    # Should be tightened
    ES = fill(zero(Tt), n)
    LS = fill(2 * span, n)

    # Resources
    b = res_req
    B = res_lim.r
    R = length(B)

    # Dependency edges
    E = EdgeIterator(deps)
    
    # Durations
    p = durations

    model = Model(with_optimizer(GLPK.Optimizer))

    # Event time variables
    @variable model t[0:n] >= 0.0

    # Project timespan
    @variable model Cmax

    # Event-activity assignment
    @variable model z[1:n, 0:n] Bin

    # Objective
    @objective model Min Cmax

    # Constraints
    @constraint model [i=1:n] sum(z[i,e] for e in 0:n) >= 1.0 
    @constraint model [i=1:n] z[i,0] == 0.0 

    @constraint model [i=1:n, e=1:n] Cmax >= t[e] + (z[i,e] - z[i,e-1])*p[i]

    @constraint model t[0] == 0.0

    @constraint model [e=0:n-1] t[e+1] >= t[e]

    @constraint model [e=1:n, f=1:n, i=1:n; f > e] t[f] >= t[e] + ((z[i,e] - z[i,e-1]) - (z[i,f] - z[i,f-1]) - 1)*p[i]
    
    @constraint model [e=1:n, i=1:n] sum(z[i,f] for f in 0:e-1) <= e*(1 - (z[i,e] - z[i,e-1]))
    
    @constraint model [e=1:n, i=1:n] sum(z[i,f] for f in e:n-1) <= (n - e)*(1 + (z[i,e] - z[i,e-1]))
    
    @constraint model [(i,j)=E, e=0:n] z[i,e] + sum(z[j,f] for f in 0:e) <= 1 + (1 - z[i,e])*e
    
    @constraint model [k=1:R, e=0:n] sum(b[i][k]*z[i,e] for i in 1:n) <= B[k]

    @constraint model [e=0:n, i=1:n] ES[i] * z[i,e] <= t[e]

    @constraint model [e=1:n, i=1:n] t[e] <= LS[i] * (z[i,e] - z[i,e-1]) + LS[n] * (1 - (z[i,e] - z[i,e-1]))

    return OnOffEventModel(project, model, (t = t, z = z, Cmax = Cmax))
end

function JuMP.optimize!(model::OnOffEventModel)
    @unpack jump_model, project, vars = model
    n = project.n
    optimize!(jump_model)

    start_times = zeros(Float64, n) 
    for i in 1:n
        for e in 1:n
            if value(vars.z[i,e]) == 1
                start_times[i] = value(vars.t[e])
            end
        end
    end

    return Schedule(start_times)
end

function ResourcesTrace(model::OnOffEventModel, schedule::Schedule; kwargs...)
    return ResourcesTrace(model.project, schedule; kwargs...)
end
