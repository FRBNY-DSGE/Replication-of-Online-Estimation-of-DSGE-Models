# This file contains wrapper functions for functions called in
# the RealtimeData.jl module for convenience of use within the
# SMCProject.jl module.

function load_realtime_data(m::AbstractModel; cond_type::Symbol = :none,
                            try_disk::Bool = true, save::Bool = true,
                            verbose::Symbol = :low)

    # Populate the necessary fields in settings to call
    # the load_realtime_data function from RealtimeData.jl
    settings = Dict{Symbol, Any}()
    settings[:hpfilter_population]      = get_setting(m, :hpfilter_population)
    settings[:rate_expectations_source] = get_setting(m, :rate_expectations_source)
    settings[:rate_expectations_post_liftoff] = get_setting(m, :rate_expectations_post_liftoff)
    settings[:use_staff_forecasts]            = get_setting(m, :use_staff_forecasts)

    return load_realtime_data(m, :bluechip, settings; cond_type = cond_type,
                              try_disk = try_disk, save = save, verbose = verbose)
end


function load_realtime_population_growth(m::AbstractModel, vint::String, year::Int, quarter::Int; try_disk::Bool = true, save::Bool = true, verbose::Symbol = :low)

    # Populate the necessary fields in settings to call
    # the load_realtime_data function from RealtimeData.jl
    settings = Dict{Symbol, Any}()
    settings[:hpfilter_population]      = get_setting(m, :hpfilter_population)

    load_realtime_population_growth(vint, year, quarter, settings, try_disk = try_disk, save = save, verbose = verbose)
end
