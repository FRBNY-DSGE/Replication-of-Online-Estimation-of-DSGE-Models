function load_reference_forecast_var(year::Int, quarter::Int, reference_forecast::Symbol,
                                     series::DataFrame, var::Symbol)
    @show reference_forecast
    # Find index of forecast corresponding to this year and quarter
    datestr = reference_forecast_vintage(year, quarter, reference_forecast)
    date_index = something(findfirst(isequal(datestr), series[:date]), 0)

    # Assign t-quarters-ahead forecast of var to df[t, var]
    horizons = reference_forecast_horizons(reference_forecast)
    forecast = NaN*zeros(horizons)
    if date_index == 0
        warn("$year-Q$quarter $(reference_forecast_longname(reference_forecast)) $var forecast missing")
    else
        ref_var = replace(string(var), "obs_" => "")
        for t = 1:horizons
            colname = Symbol(ref_var, "_", t)
            forecast[t] = series[date_index, colname]
        end
    end
    return forecast
end

function load_reference_forecast(year::Int, quarter::Int, reference_forecast::Symbol)
    # Dates
    horizons = reference_forecast_horizons(reference_forecast)
    start_date = DSGE.quartertodate(year, quarter)
    end_date   = DSGE.iterate_quarters(start_date, horizons - 1)
    dates      = DSGE.quarter_range(start_date, end_date)

    df = DataFrame(date = dates)
    datadir = joinpath("$(SMC_DIR)/save/input_data/data/realtime/", "other_forecasts")

    for var in realtime_vars(reference_forecast)
        # Read in all forecasts
        if reference_forecast == :bluechip
            ref_var = "forecast_" * replace(string(var), "obs_" => "")
        else
            ref_var = string(reference_forecast) * "_" * replace(string(var), "obs_" => "")
        end
        filepath = joinpath(datadir, ref_var * "_forecast.csv")
        series = CSV.read(filepath)

        # Assign forecast of var to column of df
        df[var] = load_reference_forecast_var(year, quarter, reference_forecast, series, var)
    end

    return df
end

function read_all_reference_forecasts(reference_forecast::Symbol)
    println("Reading $(reference_forecast_longname(reference_forecast)) forecasts...")

    # Initialize dictionary
    forecasts = OrderedDict{Tuple{Int, Int}, DataFrame}()
    horizons = reference_forecast_horizons(reference_forecast)

    for (y, q) in plot_settings[:realtime_sample]
        start_date        = DSGE.quartertodate(y, q)
        end_date          = DSGE.iterate_quarters(start_date, horizons - 1)
        dates             = DSGE.quarter_range(start_date, end_date)
        forecasts[(y, q)] = DataFrame(date = dates)
    end

    datadir = joinpath("$(SMC_DIR)/save/input_data/data/realtime/other_forecasts/", "other_forecasts")
    for var in realtime_vars(reference_forecast)
        # Read in all forecasts
        ref_var = string(reference_forecast) * "_" * replace(string(var), "obs_" => "")
        filepath = joinpath(datadir, ref_var * "_forecast.csv")
        series = CSV.read(filepath)

        # Assign forecast of var to column of forecasts[(y, q)]
        for (y, q) in plot_settings[:realtime_sample]
            forecasts[(y, q)][var] = load_reference_forecast_var(y, q, reference_forecast, series, var)
        end
    end

    return forecasts
end
