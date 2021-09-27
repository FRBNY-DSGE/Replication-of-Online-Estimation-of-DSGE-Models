function prepare_model(model::Symbol, year::Int, quarter::Int, estimation_date::String;
                       subspec::String = "", iteration::Int = 0,
                       data_spec::Int = 0, est_spec::Int = 0,
                       fcast_spec::Int = 0, plot_spec::Int = 0, verbose::Symbol = :low,
                       setting_overrides::Dict{Symbol, Setting} = Dict{Symbol, Setting}())
    # Load default settings
    default_settings = initialize_default_settings(model, year, quarter, estimation_date;
                                                   data_spec = data_spec, est_spec = est_spec,
                                                   fcast_spec = fcast_spec, plot_spec = plot_spec,
                                                   verbose = verbose)
    if iteration != 0
        setting_overrides[:smc_iteration] = Setting(:smc_iteration, iteration, true, "iter", "The iteration label for estimations run with identical specifications")
    end

    # Construct the model
    m = construct_model(model, default_settings, subspec = subspec)

    # Setting overrides
    map(s -> m <= s, values(setting_overrides))

    return m
end

function construct_model(model::Symbol, default_settings::Dict{Symbol, Setting}; subspec::String = "")

    # Construct and return model
    constructor = eval(model)
    constructor(subspec, custom_settings = default_settings)
end

# Think about whether for historical estimations we want actual vintaged data
# or whether we can just subset out the relevant data periods from a new vintage.
function estimate_model(model::Symbol, year::Int, quarter::Int, estimation_date::String;
                        subspec::String = "", verbose::Symbol = :low,
                        data_spec::Int = 0, est_spec::Int = 0, fcast_spec::Int = 0,
                        plot_spec::Int = 0, iteration::Int = 0,
                        setting_overrides::Dict{Symbol, Setting} = Dict{Symbol, Setting}(),
                        data_override::DataFrame = DataFrame(),
                        save_intermediate::Bool = false,
                        intermediate_stage_increment::Int = 100)

    # Set overrides for the model to be estimated
    setting_overrides[:est_spec] = Setting(:est_spec, est_spec, true, "est", "Print the estimation specification in the filestring.")

    # Construct model
    m = prepare_model(model, year, quarter, estimation_date, subspec = subspec, data_spec = data_spec,
                      est_spec = est_spec, fcast_spec = fcast_spec, iteration = iteration,
                      plot_spec = plot_spec, setting_overrides = setting_overrides,
                      verbose = verbose)

    # Load data
    df = isempty(data_override) ? load_realtime_data(m) : data_override

    # Estimate
    # DSGE.smc(m, df;
    #          save_intermediate = save_intermediate,
    #          intermediate_stage_increment = intermediate_stage_increment,
    #          verbose = verbose)
    
    data = DSGE.df_to_matrix(m, df)
    DSGE.estimate(m, data; save_intermediate = save_intermediate, 
    		  intermediate_stage_increment = intermediate_stage_increment,
		  verbose = verbose)
end

function estimate_model(model::Symbol, T::Date, estimation_date::String; kwargs...)
    estimate_model(model, Dates.year(T), Dates.quarterofyear(T), estimation_date; kwargs...)
end

# T < T_star (i.e. T is the older date)
function estimate_model(model::Symbol, T::Date, T_star::Date, estimation_date::String; verbose::Symbol = :low,
                        subspec::String = "", iteration::Int = 0,
                        data_spec::Int = 0, est_spec::Int = 0, fcast_spec::Int = 0, plot_spec::Int = 0,
                        setting_overrides::Dict{Symbol, Setting} = Dict{Symbol, Setting}(),
                        data_override_T::DataFrame = DataFrame(),
                        data_override_T_star::DataFrame = DataFrame())

    # Ensure the dates are properly specified
    @assert T < T_star

    # Set common overrides for the models
    setting_overrides[:est_spec] = Setting(:est_spec, est_spec, true, "est", "Print the estimation specification in the filestring.")

    # Load in old model to construct old data/pull the old data vintage
    # and old cloud to initialized draws
    m_old = prepare_model(model, Dates.year(T), Dates.quarterofyear(T), estimation_date,
                          subspec = subspec, iteration = iteration,
                          data_spec = data_spec, est_spec = est_spec,
                          fcast_spec = fcast_spec, plot_spec = plot_spec,
                          setting_overrides = setting_overrides)

    cloud_old = ParticleCloud(load_cloud(m_old), map(x->x.key,m_old.parameters)) #DSGE.new_to_old_cloud(load_cloud(m_old))

    # Set overrides for the model to be estimated
    setting_overrides[:previous_data_vintage] = Setting(:previous_data_vintage, data_vintage(m_old), true, "prev", "Print the previous
                                                        data vintage used for tempering in the filestring.")

    # Construct model
    m_star = prepare_model(model, Dates.year(T_star), Dates.quarterofyear(T_star), estimation_date,
                           subspec = subspec, iteration = iteration,
                           data_spec = data_spec, est_spec = est_spec,
                           fcast_spec = fcast_spec, plot_spec = plot_spec,
                           setting_overrides = setting_overrides)

    # Load data
    df_old  = isempty(data_override_T) ? load_realtime_data(m_old) : data_override_T
    df_star = isempty(data_override_T_star) ? load_realtime_data(m_star) : data_override_T_star
    data_old  = df_to_matrix(m_old, df_old)
    data_star = df_to_matrix(m_star, df_star)

    # Estimate tempering T to T_star
    smc2(m_star, data_star; old_data = data_old, old_cloud = cloud_old, verbose = verbose)
end

# estimation_date is the date that the estimations were run
function calculate_predictive_density_model(model::Symbol, T0::Date, T::Date,
                                            input_type::Symbol, cond_type::Symbol,
                                            horizon::Int, predicted_variables::Vector{Symbol},
                                            estimation_date::String, sampling_method::Symbol;
                                            point_forecast::Bool = false,
                                            save_date::String = estimation_date,
                                            verbose::Symbol = :low, subspec::String = "",
                                            data_spec::Int = 0, est_spec::Int = 0, fcast_spec::Int = 0,
                                            parallel::Bool = false, use_final_realized_as_observed::Bool = true,
                                            setting_overrides::Dict{Symbol, Setting} = Dict{Symbol, Setting}(),
                                            save_results::Bool = true, first_estimation_tempered::Bool = false,
                                            save_aux_dir::String = "")

    # Set common overrides for the models
    setting_overrides[:sampling_method] = Setting(:sampling_method, sampling_method)
    setting_overrides[:cond_type] = Setting(:cond_type, string(cond_type), false, "cond", "Conditional Data Type")

    logscores = Vector{Float64}(undef, 0)

    if sampling_method == :SMC
        setting_overrides[:est_spec] = Setting(:est_spec, est_spec, true, "est", "Print the estimation specification in the filestring.")
        setting_overrides[:data_spec] = Setting(:data_spec, data_spec, false, "data", "Print the data specification in the filestring.")

        T_range_quarterly = quarter_range(T0, T)
        T_range_annual    = T0:Dates.Year(1):T
        T_range_prev      = T_range_annual[1:end-1]
        T_range_curr      = T_range_annual[2:end]

        n_years           = length(T_range_curr)

        estimation_overrides = Vector{String}(undef, DSGE.subtract_quarters(T, T0) + 1)

        # Knowing that all estimations have first forecast quarter Q4,i
        # calculate the index of the first Q4 following T0.
        # e.g. if T0 is 1991-Q4, then we want the initial indices associated to the "920110" estimation
        # to be 1991-Q4 through 1992-Q3 (indices 1 through 4) of T_range_quarterly.
        first_q4_ind = findfirst(x -> Dates.quarterofyear(x) == 4, T_range_quarterly)
        first_q4_ind = first_q4_ind == 1 ? 1 + 4 : 1
        initial_inds = 1:(first_q4_ind - 1)

        if first_estimation_tempered
            setting_overrides[:previous_data_vintage] = Setting(:previous_data_vintage, forecast_vintage(iterate_quarters(T0, -4)),
                                                                true, "prev", "Print the previous data vintage used for tempering in the filestring.")
        end

        # Populate the forecast dates using non-tempered estimations (assuming the first estimation is non-tempered)
        m_old = prepare_model(model, Dates.year(T0), Dates.quarterofyear(T0), estimation_date,
                              subspec = subspec,
                              data_spec = data_spec, est_spec = est_spec,
                              fcast_spec = fcast_spec,
                              setting_overrides = setting_overrides)

        # So that this exists outside of the scope of the for loop
        m_new = deepcopy(m_old)

        estimation_overrides[initial_inds] .= rawpath(m_old, "estimate", "smcsave.h5")

        for (i, T_prev, T_curr) in zip(1:n_years, T_range_prev, T_range_curr)
            setting_overrides[:previous_data_vintage] = Setting(:previous_data_vintage, forecast_vintage(T_prev), true, "prev", "Print the previous
                                                                data vintage used for tempering in the filestring.")

            # Construct model
            m_new = prepare_model(model, Dates.year(T_curr), Dates.quarterofyear(T_curr), estimation_date,
                                  subspec = subspec,
                                  data_spec = data_spec, est_spec = est_spec,
                                  fcast_spec = fcast_spec,
                                  setting_overrides = setting_overrides)

            # Maximally go up to the total number of dates, T - T0 + 1.
            incremented_inds_temp = initial_inds .+ 4*i
            incremented_inds = incremented_inds_temp.start:min(incremented_inds_temp.stop, DSGE.subtract_quarters(T, T0) + 1)

            estimation_overrides[incremented_inds] .= rawpath(m_new, "estimate", "smcsave.h5")
        end

        logscores = compute_predictive_densities(m_old, input_type, T0, T, horizon,
                                                 predicted_variables,
                                                 point_forecast = point_forecast, cond_type = cond_type,
                                                 use_final_realized_as_observed = use_final_realized_as_observed,
                                                 estimation_overrides = estimation_overrides, data_spec = data_spec,
                                                 est_spec = est_spec, fcast_spec = fcast_spec, parallel = parallel)

        if save_results
            m_new <= Setting(:predictive_density_horizon, horizon, true, "hor", "The length of the averaging horizon that the predictive densities were calculated at. E.g. horizon = 4 => 4-quarter ahead predictive densities")
            m_new <= Setting(:cond_type, string(cond_type), true, "cond", "Conditional type")
            m_new <= Setting(:data_spec, data_spec, true, "data", "Data specification")
            m_new <= Setting(:sampling_method, sampling_method, true, "samp", "The kind of sampling method used. Either :MH or :SMC")
            m_new <= Setting(:T0, T0, true, "T0", "The first forecast date")
            m_new <= Setting(:T, T, true, "T", "The final forecast date")
            m_new <= Setting(:data_vintage, data_vintage(m_new), false, "vint", "Don't print data vintage, since T0 and T info is sufficient")
            m_new <= Setting(:previous_data_vintage, data_vintage(m_old), false, "prev", "Don't print previous data vintage, since T0 and T info is sufficient")

            # For saving things back to their SMCProject save_date dated directory
            if !isempty(save_aux_dir)
                m_new <= Setting(:saveroot, "$SMC_DIR/save/$save_date/$save_aux_dir")
            else
                m_new <= Setting(:saveroot, "$SMC_DIR/save/$save_date")
            end

            save_path = point_forecast ? rawpath(m_new, "forecast", "point_logscores.jld2") : rawpath(m_new, "forecast", "logscores.jld2")
        end
    elseif sampling_method == :MH
        T_range = T0:Dates.Year(1):T

        setting_overrides[:realtime_est_spec] = Setting(:realtime_est_spec, 1, true, "est", "The est spec used in the realtime forecasting project, whose estimations we are loading.")

        m = prepare_model(model, Dates.year(T0), Dates.quarterofyear(T0), estimation_date,
                          subspec = subspec,
                          data_spec = data_spec, est_spec = est_spec,
                          fcast_spec = fcast_spec,
                          setting_overrides = setting_overrides)

        logscores = compute_predictive_densities(m, input_type, T0, T, horizon,
                                                 predicted_variables,
                                                 point_forecast = point_forecast, cond_type = cond_type,
                                                 use_final_realized_as_observed = use_final_realized_as_observed,
                                                 data_spec = data_spec, est_spec = est_spec,
                                                 fcast_spec = fcast_spec, parallel = parallel)

        if save_results
            m <= Setting(:predictive_density_horizon, horizon, true, "hor", "The length of the averaging horizon that the predictive densities were calculated at. E.g. horizon = 4 => 4-quarter ahead predictive densities")
            m <= Setting(:sampling_method, sampling_method, true, "samp", "The kind of sampling method used. Either :MH or :SMC")
            m <= Setting(:T0, T0, true, "T0", "The first forecast date")
            m <= Setting(:T, T, true, "T", "The final forecast date")
            m <= Setting(:data_vintage, data_vintage(m), false, "vint", "Don't print data vintage, since T0 and T info is sufficient")
            m <= Setting(:previous_data_vintage, data_vintage(m), false, "prev", "Don't print previous data vintage, since T0 and T info is sufficient")
            m <= Setting(:cond_type, cond_type, true, "cond", "Conditional type")
            m <= Setting(:data_spec, data_spec, true, "data", "Data specification")

            # For saving things back to their SMCProject save_date dated directory
            if !isempty(save_aux_dir)
                m <= Setting(:saveroot, "$DIR/smc/nyfed_dsge/SMCProject/save/$save_date/$save_aux_dir")
            else
                m <= Setting(:saveroot, "$DIR/smc/nyfed_dsge/SMCProject/save/$save_date")
            end

            save_path = point_forecast ? rawpath(m, "forecast", "point_logscores.jld2") : rawpath(m, "forecast", "logscores.jld2")
        end
    else
        throw("Invalid sampling_method provided. Must be either :SMC or :MH")
    end

    if save_results
        save(save_path, "logscores", logscores)
        println("Wrote $save_path")
    end

    return logscores
end
