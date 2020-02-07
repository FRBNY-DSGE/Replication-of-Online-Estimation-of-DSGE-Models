function load_predictive_densities(model::Symbol, T0::Date, T::Date,
                                   input_type::Symbol, cond_type::Symbol,
                                   horizon::Int, save_date::String, sampling_method::Symbol;
                                   verbose::Symbol = :low, subspec::String = "",
                                   data_spec::Int = 0, est_spec::Int = 0, fcast_spec::Int = 0,
                                   point_forecast::Bool = false,
                                   setting_overrides::Dict{Symbol, Setting} = Dict{Symbol, Setting}(),
                                   save_aux_dir::String = "")

    setting_overrides[:cond_type] = Setting(:cond_type, string(cond_type), true, "cond", "Conditional Data Type")
    setting_overrides[:data_spec] = Setting(:data_spec, data_spec, true, "data", "Print the data specification in the filestring.")

    m = prepare_model(model, Dates.year(T0), Dates.quarterofyear(T0), save_date, subspec = subspec,
                      data_spec = data_spec, est_spec = est_spec, fcast_spec = fcast_spec, setting_overrides = setting_overrides)

    if sampling_method == :SMC
        # Changing the filestring to reflect the settings the predictive densities were
        # calculated under
        m <= Setting(:est_spec, est_spec, true, "est", "Print the estimation specification in the filestring.")
    elseif sampling_method == :MH
        m <= Setting(:realtime_est_spec, 1, true, "est", "The est spec used in the realtime forecasting project, whose estimations we are loading.")
    else
        throw("Invalid sampling_method. Must be :SMC or :MH")
    end
    m <= Setting(:predictive_density_horizon, horizon, true, "hor", "The length of the averaging horizon that the predictive densities were calculated at. E.g. horizon = 4 => 4-quarter ahead predictive densities")
    m <= Setting(:sampling_method, sampling_method, true, "samp", "The kind of sampling method used. Either :MH or :SMC")
    m <= Setting(:T0, T0, true, "T0", "The first forecast date")
    m <= Setting(:T, T, true, "T", "The final forecast date")
    m <= Setting(:data_vintage, data_vintage(m), false, "vint", "Don't print data vintage, since T0 and T info is sufficient")
    m <= Setting(:previous_data_vintage, data_vintage(m), false, "prev", "Don't print previous data vintage, since T0 and T info is sufficient")

    # For saving things back to their SMCProject save_date dated directory
    if !isempty(save_aux_dir)
        m <= Setting(:saveroot, "$SMC_DIR/save/$save_date/$save_aux_dir")
    else
        m <= Setting(:saveroot, "$SMC_DIR/save/$save_date")
    end

    if point_forecast
        println(rawpath(m, "forecast", "point_logscores.jld2"))
        logscores = load(rawpath(m, "forecast", "point_logscores.jld2"))["logscores"]
    else
        println(rawpath(m, "forecast", "logscores.jld2"))
        logscores = load(rawpath(m, "forecast", "logscores.jld2"))["logscores"]
    end

    return logscores
end
