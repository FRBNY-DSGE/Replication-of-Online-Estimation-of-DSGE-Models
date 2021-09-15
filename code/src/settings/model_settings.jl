# est_spec = 1 will be the "fixed" schedule specification for all models
function default_est_settings!(model::Symbol, est_settings::Dict{Symbol, Setting})
    if model == :AnSchorfheide
        est_settings[:n_particles] = Setting(:n_particles, 3000)
        est_settings[:n_Φ] = Setting(:n_Φ, 200)
        est_settings[:λ] = Setting(:λ, 2.)
        est_settings[:n_smc_blocks] = Setting(:n_smc_blocks, 1)
        est_settings[:n_mh_steps_smc] = Setting(:n_mh_steps_smc, 1)
        est_settings[:step_size_smc] = Setting(:step_size_smc, 0.4)
        est_settings[:target_accept] = Setting(:target_accept, 0.25)
        est_settings[:mixture_proportion] = Setting(:mixture_proportion, .9)
        est_settings[:resampling_threshold] = Setting(:resampling_threshold, .5)
        est_settings[:adaptive_tempering_target_smc] = Setting(:adaptive_tempering_target_smc, 0.0)
    elseif model == :SmetsWoutersOrig
        est_settings[:n_particles] = Setting(:n_particles, 12_000)
        est_settings[:n_Φ] = Setting(:n_Φ, 500)
        est_settings[:λ] = Setting(:λ, 2.1)
        est_settings[:n_smc_blocks] = Setting(:n_smc_blocks, 3)
        est_settings[:n_mh_steps_smc] = Setting(:n_mh_steps_smc, 1)
        est_settings[:step_size_smc] = Setting(:step_size_smc, 0.4)
        est_settings[:target_accept] = Setting(:target_accept, 0.25)
        est_settings[:mixture_proportion] = Setting(:mixture_proportion, .9)
        est_settings[:resampling_threshold] = Setting(:resampling_threshold, 0.5)
        est_settings[:adaptive_tempering_target_smc] = Setting(:adaptive_tempering_target_smc, 0.0)
        est_settings[:date_presample_start] = Setting(:date_presample_start, quartertodate("1965-Q4"))
        est_settings[:date_mainsample_start] = Setting(:date_mainsample_start, quartertodate("1966-Q4"))
        #est_settings[:date_forecast_start] = Setting(:date_forecast_start, quartertodate("2005-Q1"))
        #est_settings[:date_conditional_end] = Setting(:date_conditional_end, quartertodate("2005-Q1"))
    elseif model == :SmetsWouters
    	est_settings[:sampling_method]    = Setting(:sampling_method, :MH)
	est_settings[:n_mh_simulations]   = Setting(:n_mh_simulations, 100)
        est_settings[:n_particles] = Setting(:n_particles, 12_000)
        est_settings[:n_Φ] = Setting(:n_Φ, 500)
        est_settings[:λ] = Setting(:λ, 2.1)
        est_settings[:n_smc_blocks] = Setting(:n_smc_blocks, 3)
        est_settings[:n_mh_steps_smc] = Setting(:n_mh_steps_smc, 1)
        est_settings[:step_size_smc] = Setting(:step_size_smc, 0.4)
        est_settings[:target_accept] = Setting(:target_accept, 0.25)
        est_settings[:mixture_proportion] = Setting(:mixture_proportion, .9)
        est_settings[:resampling_threshold] = Setting(:resampling_threshold, 0.5)
        est_settings[:adaptive_tempering_target_smc] = Setting(:adaptive_tempering_target_smc, 0.0)
    elseif model == :Model805
        est_settings[:n_particles] = Setting(:n_particles, 12_000)
        est_settings[:n_Φ] = Setting(:n_Φ, 500)
        est_settings[:λ] = Setting(:λ, 2.1)
        est_settings[:n_smc_blocks] = Setting(:n_smc_blocks, 3)
        est_settings[:n_mh_steps_smc] = Setting(:n_mh_steps_smc, 1)
        est_settings[:step_size_smc] = Setting(:step_size_smc, 0.4)
        est_settings[:target_accept] = Setting(:target_accept, 0.25)
        est_settings[:mixture_proportion] = Setting(:mixture_proportion, .9)
        est_settings[:resampling_threshold] = Setting(:resampling_threshold, 0.5)
        est_settings[:adaptive_tempering_target_smc] = Setting(:adaptive_tempering_target_smc, 0.0)
    elseif model == :Model904
        est_settings[:n_particles] = Setting(:n_particles, 12_000)
        est_settings[:n_Φ] = Setting(:n_Φ, 500)
        est_settings[:λ] = Setting(:λ, 2.1)
        est_settings[:n_smc_blocks] = Setting(:n_smc_blocks, 3)
        est_settings[:n_mh_steps_smc] = Setting(:n_mh_steps_smc, 1)
        est_settings[:step_size_smc] = Setting(:step_size_smc, 0.4)
        est_settings[:target_accept] = Setting(:target_accept, 0.25)
        est_settings[:mixture_proportion] = Setting(:mixture_proportion, .9)
        est_settings[:resampling_threshold] = Setting(:resampling_threshold, 0.5)
        est_settings[:adaptive_tempering_target_smc] = Setting(:adaptive_tempering_target_smc, 0.0)
    else
        throw("We have not implemented the infrastructure to support model $model.")
    end
end

function update_AnSchorfheide_settings(est_spec::Int, fcast_spec::Int, plot_spec::Int;
                                       default_setting::Bool = false,
                                       verbose::Symbol = :low)
    est_settings   = Dict{Symbol, Setting}(:settings_spec => Setting(:settings_spec, :est))
    fcast_settings = Dict{Symbol, Setting}(:settings_spec => Setting(:settings_spec, :fcast))
    plot_settings  = Dict{Symbol, Setting}(:settings_spec => Setting(:settings_spec, :plot))

    # Estimation settings
    if est_spec == 0
        nothing
    elseif est_spec == 1 # Fixed, n_mh = 1
        default_est_settings!(:AnSchorfheide, est_settings)
    elseif est_spec == 2 # a = 0.98, n_mh = 1
        default_est_settings!(:AnSchorfheide, est_settings)
        est_settings[:adaptive_tempering_target_smc] = Setting(:adaptive_tempering_target_smc, 0.98)
    elseif est_spec == 3 # a = 0.98, n_mh = 3
        default_est_settings!(:AnSchorfheide, est_settings)
        est_settings[:adaptive_tempering_target_smc] = Setting(:adaptive_tempering_target_smc, 0.98)
        est_settings[:n_mh_steps_smc] = Setting(:n_mh_steps_smc, 3)
    elseif est_spec == 4 # a = 0.98, n_mh = 5
        default_est_settings!(:AnSchorfheide, est_settings)
        est_settings[:adaptive_tempering_target_smc] = Setting(:adaptive_tempering_target_smc, 0.98)
        est_settings[:n_mh_steps_smc] = Setting(:n_mh_steps_smc, 5)
    elseif est_spec == 5 # a = 0.97, n_mh = 1
        default_est_settings!(:AnSchorfheide, est_settings)
        est_settings[:adaptive_tempering_target_smc] = Setting(:adaptive_tempering_target_smc, 0.97)
    elseif est_spec == 6 # a = 0.97, n_mh = 3
        default_est_settings!(:AnSchorfheide, est_settings)
        est_settings[:adaptive_tempering_target_smc] = Setting(:adaptive_tempering_target_smc, 0.97)
        est_settings[:n_mh_steps_smc] = Setting(:n_mh_steps_smc, 3)
    elseif est_spec == 7 # a = 0.97, n_mh = 5
        default_est_settings!(:AnSchorfheide, est_settings)
        est_settings[:adaptive_tempering_target_smc] = Setting(:adaptive_tempering_target_smc, 0.97)
        est_settings[:n_mh_steps_smc] = Setting(:n_mh_steps_smc, 5)
    elseif est_spec == 8 # Testing
        default_est_settings!(:AnSchorfheide, est_settings)
        est_settings[:n_particles] = Setting(:n_particles, 800)
        est_settings[:n_Φ] = Setting(:n_Φ, 100)
    elseif est_spec == 9 # a = 0.0, n_mh = 3
        default_est_settings!(:AnSchorfheide, est_settings)
        est_settings[:adaptive_tempering_target_smc] = Setting(:adaptive_tempering_target_smc, 0.0)
        est_settings[:n_mh_steps_smc] = Setting(:n_mh_steps_smc, 3)
    elseif est_spec == 10 # a = 0.0, nmh = 5
        default_est_settings!(:AnSchorfheide, est_settings)
        est_settings[:adaptive_tempering_target_smc] = Setting(:adaptive_tempering_target_smc, 0.0)
        est_settings[:n_mh_steps_smc] = Setting(:n_mh_steps_smc, 5)
    elseif est_spec == 11 # a = 0.95, n_mh = 3
        default_est_settings!(:AnSchorfheide, est_settings)
        est_settings[:adaptive_tempering_target_smc] = Setting(:adaptive_tempering_target_smc, 0.95)
        est_settings[:n_mh_steps_smc] = Setting(:n_mh_steps_smc, 3)
    elseif est_spec == 12 # a = 0.95, nmh = 5
        default_est_settings!(:AnSchorfheide, est_settings)
        est_settings[:adaptive_tempering_target_smc] = Setting(:adaptive_tempering_target_smc, 0.95)
        est_settings[:n_mh_steps_smc] = Setting(:n_mh_steps_smc, 5)
    elseif est_spec == 13 # a = 0.9, n_mh = 3
        default_est_settings!(:AnSchorfheide, est_settings)
        est_settings[:adaptive_tempering_target_smc] = Setting(:adaptive_tempering_target_smc, 0.9)
        est_settings[:n_mh_steps_smc] = Setting(:n_mh_steps_smc, 3)
    elseif est_spec == 14 # a = 0.9, nmh = 5
        default_est_settings!(:AnSchorfheide, est_settings)
        est_settings[:adaptive_tempering_target_smc] = Setting(:adaptive_tempering_target_smc, 0.9)
        est_settings[:n_mh_steps_smc] = Setting(:n_mh_steps_smc, 5)
    elseif est_spec == 15 # a = 0.95, nmh = 1
        default_est_settings!(:AnSchorfheide, est_settings)
        est_settings[:adaptive_tempering_target_smc] = Setting(:adaptive_tempering_target_smc, 0.95)
        est_settings[:n_mh_steps_smc] = Setting(:n_mh_steps_smc, 1)
    elseif est_spec == 16 # a = 0.9, nmh = 1
        default_est_settings!(:AnSchorfheide, est_settings)
        est_settings[:adaptive_tempering_target_smc] = Setting(:adaptive_tempering_target_smc, 0.9)
        est_settings[:n_mh_steps_smc] = Setting(:n_mh_steps_smc, 1)
    elseif est_spec == 17 # a = 0.9, nmh = 2
        default_est_settings!(:AnSchorfheide, est_settings)
        est_settings[:adaptive_tempering_target_smc] = Setting(:adaptive_tempering_target_smc, 0.9)
        est_settings[:n_mh_steps_smc] = Setting(:n_mh_steps_smc, 2)
    elseif est_spec == 18 # a = 0.95, nmh = 2
        default_est_settings!(:AnSchorfheide, est_settings)
        est_settings[:adaptive_tempering_target_smc] = Setting(:adaptive_tempering_target_smc, 0.95)
        est_settings[:n_mh_steps_smc] = Setting(:n_mh_steps_smc, 2)
    elseif est_spec == 19 # a = 0.97, nmh = 2
        default_est_settings!(:AnSchorfheide, est_settings)
        est_settings[:adaptive_tempering_target_smc] = Setting(:adaptive_tempering_target_smc, 0.97)
        est_settings[:n_mh_steps_smc] = Setting(:n_mh_steps_smc, 2)
    elseif est_spec == 20 # a = 0.98, nmh = 2
        default_est_settings!(:AnSchorfheide, est_settings)
        est_settings[:adaptive_tempering_target_smc] = Setting(:adaptive_tempering_target_smc, 0.98)
        est_settings[:n_mh_steps_smc] = Setting(:n_mh_steps_smc, 2)
    elseif est_spec == 21 # a = 0.9, nmh = 7
        default_est_settings!(:AnSchorfheide, est_settings)
        est_settings[:adaptive_tempering_target_smc] = Setting(:adaptive_tempering_target_smc, 0.9)
        est_settings[:n_mh_steps_smc] = Setting(:n_mh_steps_smc, 7)
    elseif est_spec == 22 # a = 0.95, nmh = 7
        default_est_settings!(:AnSchorfheide, est_settings)
        est_settings[:adaptive_tempering_target_smc] = Setting(:adaptive_tempering_target_smc, 0.95)
        est_settings[:n_mh_steps_smc] = Setting(:n_mh_steps_smc, 7)
    elseif est_spec == 23 # a = 0.97, nmh = 7
        default_est_settings!(:AnSchorfheide, est_settings)
        est_settings[:adaptive_tempering_target_smc] = Setting(:adaptive_tempering_target_smc, 0.97)
        est_settings[:n_mh_steps_smc] = Setting(:n_mh_steps_smc, 7)
    elseif est_spec == 24 # a = 0.98, nmh = 7
        default_est_settings!(:AnSchorfheide, est_settings)
        est_settings[:adaptive_tempering_target_smc] = Setting(:adaptive_tempering_target_smc, 0.98)
        est_settings[:n_mh_steps_smc] = Setting(:n_mh_steps_smc, 7)
    else
        error("Invalid est_spec: $est_spec")
    end
    if est_spec == 0
        if VERBOSITY[verbose] >= VERBOSITY[:low]
            if default_setting
                throw("Must initialize est_spec to an actual specification, i.e. est_spec != 0 when initializing default settings.")
            else
                println("Estimation settings unchanged. est_spec = $est_spec")
            end
        end
    else
        if VERBOSITY[verbose] >= VERBOSITY[:low]
            if default_setting
                println("Estimation setting initialized to: est_spec = $est_spec")
            else
                println("Estimation settings updated to: est_spec = $est_spec")
            end
        end
    end

    # Forecasting settings

    # Plotting settings

    return est_settings, fcast_settings, plot_settings
end

function update_SmetsWoutersOrig_settings(est_spec::Int, fcast_spec::Int, plot_spec::Int;
                                          default_setting::Bool = false, verbose::Symbol = :low)
    est_settings   = Dict{Symbol, Setting}(:settings_spec => Setting(:settings_spec, :est))
    fcast_settings = Dict{Symbol, Setting}(:settings_spec => Setting(:settings_spec, :fcast))
    plot_settings  = Dict{Symbol, Setting}(:settings_spec => Setting(:settings_spec, :plot))

    # Estimation settings
    if est_spec == 0
        nothing
    elseif est_spec == 1 # Fixed, n_mh = 1
        default_est_settings!(:SmetsWoutersOrig, est_settings)
    elseif est_spec == 2 # \alpha = 0.98, n_mh = 1
        default_est_settings!(:SmetsWoutersOrig, est_settings)
        est_settings[:adaptive_tempering_target_smc] = Setting(:adaptive_tempering_target_smc, 0.98)
        est_settings[:n_mh_steps_smc] = Setting(:n_mh_steps_smc, 1)
    elseif est_spec == 3 # \alpha = 0.98, n_mh = 3
        default_est_settings!(:SmetsWoutersOrig, est_settings)
        est_settings[:adaptive_tempering_target_smc] = Setting(:adaptive_tempering_target_smc, 0.98)
        est_settings[:n_mh_steps_smc] = Setting(:n_mh_steps_smc, 3)
    elseif est_spec == 4 # \alpha = 0.98, n_mh = 5
        default_est_settings!(:SmetsWoutersOrig, est_settings)
        est_settings[:adaptive_tempering_target_smc] = Setting(:adaptive_tempering_target_smc, 0.98)
        est_settings[:n_mh_steps_smc] = Setting(:n_mh_steps_smc, 5)
    elseif est_spec == 5 # \alpha = 0.97, n_mh = 1
        default_est_settings!(:SmetsWoutersOrig, est_settings)
        est_settings[:adaptive_tempering_target_smc] = Setting(:adaptive_tempering_target_smc, 0.97)
        est_settings[:n_mh_steps_smc] = Setting(:n_mh_steps_smc, 1)
    elseif est_spec == 8 # \alpha = 0.97, n_mh = 3
        default_est_settings!(:SmetsWoutersOrig, est_settings)
        est_settings[:adaptive_tempering_target_smc] = Setting(:adaptive_tempering_target_smc, 0.97)
        est_settings[:n_mh_steps_smc] = Setting(:n_mh_steps_smc, 3)
    elseif est_spec == 9 # \alpha = 0.97, n_mh = 5
        default_est_settings!(:SmetsWoutersOrig, est_settings)
        est_settings[:adaptive_tempering_target_smc] = Setting(:adaptive_tempering_target_smc, 0.97)
        est_settings[:n_mh_steps_smc] = Setting(:n_mh_steps_smc, 5)
    elseif est_spec == 6 # \alpha = 0.95, n_mh = 1
        default_est_settings!(:SmetsWoutersOrig, est_settings)
        est_settings[:adaptive_tempering_target_smc] = Setting(:adaptive_tempering_target_smc, 0.95)
        est_settings[:n_mh_steps_smc] = Setting(:n_mh_steps_smc, 1)
    elseif est_spec == 10 # \alpha = 0.95, n_mh = 3
        default_est_settings!(:SmetsWoutersOrig, est_settings)
        est_settings[:adaptive_tempering_target_smc] = Setting(:adaptive_tempering_target_smc, 0.95)
        est_settings[:n_mh_steps_smc] = Setting(:n_mh_steps_smc, 3)
    elseif est_spec == 11 # \alpha = 0.95, n_mh = 5
        default_est_settings!(:SmetsWoutersOrig, est_settings)
        est_settings[:adaptive_tempering_target_smc] = Setting(:adaptive_tempering_target_smc, 0.95)
        est_settings[:n_mh_steps_smc] = Setting(:n_mh_steps_smc, 5)
    elseif est_spec == 7 # \alpha = 0.90, n_mh = 1
        default_est_settings!(:SmetsWoutersOrig, est_settings)
        est_settings[:adaptive_tempering_target_smc] = Setting(:adaptive_tempering_target_smc, 0.90)
        est_settings[:n_mh_steps_smc] = Setting(:n_mh_steps_smc, 1)
    elseif est_spec == 12 # \alpha = 0.90, n_mh = 3
        default_est_settings!(:SmetsWoutersOrig, est_settings)
        est_settings[:adaptive_tempering_target_smc] = Setting(:adaptive_tempering_target_smc, 0.90)
        est_settings[:n_mh_steps_smc] = Setting(:n_mh_steps_smc, 3)
    elseif est_spec == 13 # \alpha = 0.90, n_mh = 5
        default_est_settings!(:SmetsWoutersOrig, est_settings)
        est_settings[:adaptive_tempering_target_smc] = Setting(:adaptive_tempering_target_smc, 0.90)
        est_settings[:n_mh_steps_smc] = Setting(:n_mh_steps_smc, 5)
    else
        error("Invalid est_spec: $est_spec")
    end

    if est_spec == 0
        if VERBOSITY[verbose] >= VERBOSITY[:low]
            if default_setting
                throw("Must initialize est_spec to an actual specification, i.e. est_spec != 0 when initializing default settings.")
            else
                println("Estimation settings unchanged.")
            end
        end
    else
        if VERBOSITY[verbose] >= VERBOSITY[:low]
            if default_setting
                println("Estimation setting initialized to: est_spec = $est_spec")
            else
                println("Estimation settings updated to: est_spec = $est_spec")
            end
        end
    end

    # Forecasting settings

    # Plotting settings

    return est_settings, fcast_settings, plot_settings
end


function update_SmetsWouters_settings(est_spec::Int, fcast_spec::Int, plot_spec::Int;
                                      default_setting::Bool = false, verbose::Symbol = :low)
    est_settings   = Dict{Symbol, Setting}(:settings_spec => Setting(:settings_spec, :est))
    fcast_settings = Dict{Symbol, Setting}(:settings_spec => Setting(:settings_spec, :fcast))
    plot_settings  = Dict{Symbol, Setting}(:settings_spec => Setting(:settings_spec, :plot))

    # Estimation settings
    if est_spec == 0
        nothing
    elseif est_spec == 1
        default_est_settings!(:SmetsWouters, est_settings)
    elseif est_spec == 2
        default_est_settings!(:SmetsWouters, est_settings)
	est_settings[:mh_target_accept] = Setting(:mh_target_accept, 0.25)
	est_settings[:mh_adaptive_accept = Setting(:mh_adaptive_accept, true)
    elseif est_spec == 3
        default_est_settings!(:SmetsWouters, est_settings)
	est_settings[:mh_target_accept] = Setting(:mh_target_accept, 0.5)
	est_settings[:mh_adaptive_accept = Setting(:mh_adaptive_accept, true)
    elseif est_spec == 4
        default_est_settings!(:SmetsWouters, est_settings)
	est_settings[:mh_target_accept] = Setting(:mh_target_accept, 0.75)
	est_settings[:mh_adaptive_accept = Setting(:mh_adaptive_accept, true)
    elseif est_spec == 5
        default_est_settings!(:SmetsWouters, est_settings)
	est_settings[:mh_target_accept] = Setting(:mh_target_accept, 0.9)
	est_settings[:mh_adaptive_accept = Setting(:mh_adaptive_accept, true)
    # elseif est_spec == 1 # Fixed, n_mh = 1
    #     default_est_settings!(:SmetsWouters, est_settings)
    # elseif est_spec == 15 # Fixed, n_mh = 3
    #     default_est_settings!(:SmetsWouters, est_settings)
    #     est_settings[:n_mh_steps_smc] = Setting(:n_mh_steps_smc, 3)
    # elseif est_spec == 16 # Fixed, n_mh = 5
    #     default_est_settings!(:SmetsWouters, est_settings)
    #     est_settings[:n_mh_steps_smc] = Setting(:n_mh_steps_smc, 5)
    # elseif est_spec == 2 # \alpha = 0.98, n_mh = 1
    #     default_est_settings!(:SmetsWouters, est_settings)
    #     est_settings[:adaptive_tempering_target_smc] = Setting(:adaptive_tempering_target_smc, 0.98)
    #     est_settings[:n_mh_steps_smc] = Setting(:n_mh_steps_smc, 1)
    # elseif est_spec == 3 # \alpha = 0.98, n_mh = 3
    #     default_est_settings!(:SmetsWouters, est_settings)
    #     est_settings[:adaptive_tempering_target_smc] = Setting(:adaptive_tempering_target_smc, 0.98)
    #     est_settings[:n_mh_steps_smc] = Setting(:n_mh_steps_smc, 3)
    # elseif est_spec == 4 # \alpha = 0.98, n_mh = 5
    #     default_est_settings!(:SmetsWouters, est_settings)
    #     est_settings[:adaptive_tempering_target_smc] = Setting(:adaptive_tempering_target_smc, 0.98)
    #     est_settings[:n_mh_steps_smc] = Setting(:n_mh_steps_smc, 5)
    # elseif est_spec == 5 # \alpha = 0.98, n_mh = 1, n_smc_blocks = 6 (use for diffuse prior)
    #     default_est_settings!(:SmetsWouters, est_settings)
    #     est_settings[:adaptive_tempering_target_smc] = Setting(:adaptive_tempering_target_smc, 0.98)
    #     est_settings[:n_mh_steps_smc] = Setting(:n_mh_steps_smc, 1)
    #     est_settings[:n_smc_blocks] = Setting(:n_smc_blocks, 6)
    # elseif est_spec == 6 # alpha = 0.9, n_mh = 1
    #     default_est_settings!(:SmetsWouters, est_settings)
    #     est_settings[:adaptive_tempering_target_smc] = Setting(:adaptive_tempering_target_smc, 0.90)
    #     est_settings[:n_mh_steps_smc] = Setting(:n_mh_steps_smc, 1)
    # elseif est_spec == 9 # alpha = 0.9, n_mh = 3
    #     default_est_settings!(:SmetsWouters, est_settings)
    #     est_settings[:adaptive_tempering_target_smc] = Setting(:adaptive_tempering_target_smc, 0.90)
    #     est_settings[:n_mh_steps_smc] = Setting(:n_mh_steps_smc, 3)
    # elseif est_spec == 10 # alpha = 0.9, n_mh = 5
    #     default_est_settings!(:SmetsWouters, est_settings)
    #     est_settings[:adaptive_tempering_target_smc] = Setting(:adaptive_tempering_target_smc, 0.90)
    #     est_settings[:n_mh_steps_smc] = Setting(:n_mh_steps_smc, 5)
    # elseif est_spec == 7 # alpha = 0.95, n_mh = 1
    #     default_est_settings!(:SmetsWouters, est_settings)
    #     est_settings[:adaptive_tempering_target_smc] = Setting(:adaptive_tempering_target_smc, 0.95)
    #     est_settings[:n_mh_steps_smc] = Setting(:n_mh_steps_smc, 1)
    # elseif est_spec == 11 # alpha = 0.95, n_mh = 3
    #     default_est_settings!(:SmetsWouters, est_settings)
    #     est_settings[:adaptive_tempering_target_smc] = Setting(:adaptive_tempering_target_smc, 0.95)
    #     est_settings[:n_mh_steps_smc] = Setting(:n_mh_steps_smc, 3)
    # elseif est_spec == 12 # alpha = 0.95, n_mh = 5
    #     default_est_settings!(:SmetsWouters, est_settings)
    #     est_settings[:adaptive_tempering_target_smc] = Setting(:adaptive_tempering_target_smc, 0.95)
    #     est_settings[:n_mh_steps_smc] = Setting(:n_mh_steps_smc, 5)
    # elseif est_spec == 8 # alpha = 0.97, n_mh = 1
    #     default_est_settings!(:SmetsWouters, est_settings)
    #     est_settings[:adaptive_tempering_target_smc] = Setting(:adaptive_tempering_target_smc, 0.97)
    #     est_settings[:n_mh_steps_smc] = Setting(:n_mh_steps_smc, 1)
    # elseif est_spec == 13 # alpha = 0.97, n_mh = 3
    #     default_est_settings!(:SmetsWouters, est_settings)
    #     est_settings[:adaptive_tempering_target_smc] = Setting(:adaptive_tempering_target_smc, 0.97)
    #     est_settings[:n_mh_steps_smc] = Setting(:n_mh_steps_smc, 3)
    # elseif est_spec == 14 # alpha = 0.97, n_mh = 5
    #     default_est_settings!(:SmetsWouters, est_settings)
    #     est_settings[:adaptive_tempering_target_smc] = Setting(:adaptive_tempering_target_smc, 0.97)
    #     est_settings[:n_mh_steps_smc] = Setting(:n_mh_steps_smc, 5)
    else
        error("Invalid est_spec: $est_spec")
    end

    if est_spec == 0
        if VERBOSITY[verbose] >= VERBOSITY[:low]
            if default_setting
                throw("Must initialize est_spec to an actual specification, i.e. est_spec != 0 when initializing default settings.")
            else
                println("Estimation settings unchanged.")
            end
        end
    else
        if VERBOSITY[verbose] >= VERBOSITY[:low]
            if default_setting
                println("Estimation setting initialized to: est_spec = $est_spec")
            else
                println("Estimation settings updated to: est_spec = $est_spec")
            end
        end
    end

    # Forecasting settings

    # Plotting settings

    return est_settings, fcast_settings, plot_settings
end

function update_Model805_settings(est_spec::Int, fcast_spec::Int, plot_spec::Int;
                                  default_setting::Bool = false, verbose::Symbol = :low)
    est_settings   = Dict{Symbol, Setting}(:settings_spec => Setting(:settings_spec, :est))
    fcast_settings = Dict{Symbol, Setting}(:settings_spec => Setting(:settings_spec, :fcast))
    plot_settings  = Dict{Symbol, Setting}(:settings_spec => Setting(:settings_spec, :plot))

    # Estimation settings
    if est_spec == 0
        nothing
    elseif est_spec == 1 # Fixed, n_mh = 1
        default_est_settings!(:Model805, est_settings)
    elseif est_spec == 2 # \alpha = 0.98, n_mh = 1
        default_est_settings!(:Model805, est_settings)
        est_settings[:adaptive_tempering_target_smc] = Setting(:adaptive_tempering_target_smc, 0.98)
    elseif est_spec == 3 # \alpha = 0.98, n_mh = 3
        default_est_settings!(:Model805, est_settings)
        est_settings[:adaptive_tempering_target_smc] = Setting(:adaptive_tempering_target_smc, 0.98)
        est_settings[:n_mh_steps_smc] = Setting(:n_mh_steps_smc, 3)
    elseif est_spec == 4 # \alpha = 0.98, n_mh = 5
        default_est_settings!(:Model805, est_settings)
        est_settings[:adaptive_tempering_target_smc] = Setting(:adaptive_tempering_target_smc, 0.98)
        est_settings[:n_mh_steps_smc] = Setting(:n_mh_steps_smc, 5)
    elseif est_spec == 5 # \alpha = 0.98, n_mh = 1, n_smc_blocks = 6 (use for diffuse prior)
        default_est_settings!(:Model805, est_settings)
        est_settings[:adaptive_tempering_target_smc] = Setting(:adaptive_tempering_target_smc, 0.98)
        est_settings[:n_smc_blocks] = Setting(:n_smc_blocks, 6)
    else
        error("Invalid est_spec: $est_spec")
    end

    if est_spec == 0
        if VERBOSITY[verbose] >= VERBOSITY[:low]
            if default_setting
                throw("Must initialize est_spec to an actual specification, i.e. est_spec != 0 when initializing default settings.")
            else
                println("Estimation settings unchanged.")
            end
        end
    else
        if VERBOSITY[verbose] >= VERBOSITY[:low]
            if default_setting
                println("Estimation setting initialized to: est_spec = $est_spec")
            else
                println("Estimation settings updated to: est_spec = $est_spec")
            end
        end
    end

    # Forecasting settings

    # Plotting settings

    return est_settings, fcast_settings, plot_settings
end

function update_Model904_settings(est_spec::Int, fcast_spec::Int, plot_spec::Int;
                                  default_setting::Bool = false, verbose::Symbol = :low)
    est_settings   = Dict{Symbol, Setting}(:settings_spec => Setting(:settings_spec, :est))
    fcast_settings = Dict{Symbol, Setting}(:settings_spec => Setting(:settings_spec, :fcast))
    plot_settings  = Dict{Symbol, Setting}(:settings_spec => Setting(:settings_spec, :plot))

    # Estimation settings
    if est_spec == 0
        nothing
    elseif est_spec == 1 # Fixed, n_mh = 1
        default_est_settings!(:Model904, est_settings)
    elseif est_spec == 2 # \alpha = 0.98, n_mh = 1
        default_est_settings!(:Model904, est_settings)
        est_settings[:adaptive_tempering_target_smc] = Setting(:adaptive_tempering_target_smc, 0.98)
    elseif est_spec == 3 # \alpha = 0.98, n_mh = 3
        default_est_settings!(:Model904, est_settings)
        est_settings[:adaptive_tempering_target_smc] = Setting(:adaptive_tempering_target_smc, 0.98)
        est_settings[:n_mh_steps_smc] = Setting(:n_mh_steps_smc, 3)
    elseif est_spec == 4 # \alpha = 0.98, n_mh = 5
        default_est_settings!(:Model904, est_settings)
        est_settings[:adaptive_tempering_target_smc] = Setting(:adaptive_tempering_target_smc, 0.98)
        est_settings[:n_mh_steps_smc] = Setting(:n_mh_steps_smc, 5)
    elseif est_spec == 5 # \alpha = 0.98, n_mh = 1
        default_est_settings!(:Model904, est_settings)
        est_settings[:adaptive_tempering_target_smc] = Setting(:adaptive_tempering_target_smc, 0.98)
        est_settings[:n_smc_blocks] = Setting(:n_smc_blocks, 6)
    else
        error("Invalid est_spec: $est_spec")
    end

    if est_spec == 0
        if VERBOSITY[verbose] >= VERBOSITY[:low]
            if default_setting
                throw("Must initialize est_spec to an actual specification, i.e. est_spec != 0 when initializing default settings.")
            else
                println("Estimation settings unchanged.")
            end
        end
    else
        if VERBOSITY[verbose] >= VERBOSITY[:low]
            if default_setting
                println("Estimation setting initialized to: est_spec = $est_spec")
            else
                println("Estimation settings updated to: est_spec = $est_spec")
            end
        end
    end

    # Forecasting settings

    # Plotting settings

    return est_settings, fcast_settings, plot_settings
end
