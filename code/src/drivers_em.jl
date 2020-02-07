"""
```
forecast_realtime_model(model, year, quarter, reference_forecast, input_type,
    cond_type, output_vars = [:forecastobs, :forecastpseudo]; subspec = "",
    model_settings = Dict{Symbol, Setting}(), est_override = "",
    forecast_string = "", verbose = :low)

forecast_realtime_model(m, df, input_type, cond_type,
    output_vars = [:forecastobs, :forecastpseudo];
    est_override = "", forecast_string = "", verbose = :low)
```

Method 1: Forecast `model` for the given `year` and `quarter`, where the exact
vintage is determined by the `reference_forecast` (either `:bluechip` or
`:greenbook`).

Method 2: Pass in model object `m` and `DataFrame` `df`, constructed by
`prepare_realtime_model` and `load_realtime_data` respectively.

The estimation from Q1 of the `year` will be used unless `est_override` is
passed in.
"""
function forecast_model(model::Symbol, year::Int, quarter::Int, run_date::String,
                        reference_forecast::Symbol,
                        input_type::Symbol, cond_type::Symbol,
                        output_vars::Vector{Symbol} = [:histobs, :forecastobs];
                        subspec::String = "",
                        data_spec::Int = 0, est_spec::Int = 0, fcast_spec::Int = 0,
                        data_o::Matrix{Float64} = Matrix(0,0),
                        plot_spec::Int = 0,
                        setting_overrides::Dict{Symbol, Setting} = Dict{Symbol, Setting}(),
                        verbose::Symbol = :high)

    setting_overrides[:est_spec] = Setting(:est_spec, est_spec, true, "est", "Print the estimation specification in the filestring.")
   # setting_overrides[:previous_data_vintage] = Setting(:previous_data_vintage, forecast_vintage(quartertodate(string(year-1)*"-Q1")), true, "prev", "Print the previous data vintage used for tempering in the filestring.")
    setting_overrides[:forecast_jstep] = Setting(:forecast_jstep, 1)
    setting_overrides[:forecast_block_size] = Setting(:forecast_block_size, 2000)


    # Construct model
    m = prepare_model(model, year, quarter, run_date, subspec = subspec, data_spec = data_spec,
                      est_spec = est_spec, fcast_spec = fcast_spec, plot_spec = plot_spec,
                      setting_overrides = setting_overrides, verbose = verbose)

    # Load data
    df = load_realtime_data(m) #, reference_forecast, fcast_settings, cond_type = cond_type,
    #verbose = verbose)
    load_realtime_population_growth(m, data_vintage(m), year, quarter)

    if cond_type == :none
        df_aug = df
    elseif cond_type == :semi
        t1_ind = size(df, 2)
        semi_cond_data = construct_semi_cond_data(m, data_o, t1_ind)
        push!(df, [date_forecast_start(m); semi_cond_data])
    elseif cond_type == :full
        t1_ind = size(df, 2)
        full_cond_data = construct_full_cond_data(m, data_o, t1_ind)
        push!(df, [date_forecast_start(m); full_cond_data])
    end

    # Delegate
    forecast_model(m, year, df, input_type, cond_type, output_vars)

end

function forecast_model(m::AbstractModel, year::Int, df::DataFrame,
                                 input_type::Symbol, cond_type::Symbol,
                                 output_vars::Vector{Symbol} = [:histobs, :forecastobs];
                                 forecast_string::String = "",
                                 verbose::Symbol = :high)
    overrides = forecast_input_file_overrides(m)
    m_temp = deepcopy(m)
    m_temp <= Setting(:data_vintage, forecast_vintage(quartertodate(string(year)*"-Q4")))

   #= if year==1991
        nothing
    else
        m_temp <= Setting(:prev_data_vintage, forecast_vintage(quartertodate(string(year-1)*"-Q4")), true, "prev", "Print the previous data vintage")
    end=#

    overrides[:full] = rawpath(m_temp, "estimate", "smcsave.h5")

    # Forecast the model
    forecast_one(m, :full, cond_type, output_vars; df = df, forecast_string = forecast_string, verbose = verbose)
    compute_meansbands(m, input_type, cond_type, output_vars; df = df, forecast_string = forecast_string, verbose = verbose)
end

#=
function realtime_forecast_input_file!(m::AbstractModel, input_type::Symbol,
                                       est_override::String = "")

    if isempty(est_override)
        est_file = get_forecast_input_file(m, input_type)

        # Replace forecast vintage with estimation vintage
        reference_forecast = get_reference_forecast(m)
        est_file = replace(est_file, data_vintage(m), estimation_vintage(reference_forecast, data_vintage(m)))

        # Replace actual subspec with default subspec
        model = realtime_unspec(m)
        est_file = replace(est_file, m.subspec, realtime_subspec(model))

        # Remove FCAST_SPEC
        est_file = replace(est_file, "_fcast=$FCAST_SPEC", "")
    else
        est_file = est_override
    end

    overrides = forecast_input_file_overrides(m)
    overrides[input_type] = est_file
end=#
