function load_handbook_struct(reference_forecast)
    if reference_forecast == :bluechip
        fn = "/data/dsge_data_dir/realtime/save/bluechip/OLD_bchip_and_vintage_data_201202-03/bluechip.mat"
        mat_struct = matopen(fn, "r") do file
            read(file, "bchip")
        end
        return mat_struct

    elseif reference_forecast == :greenbook
        error("load_handbook_struct not yet implemented for the Greenbook")
    end
end

function load_handbook_finals(reference_forecast::Symbol)

    mat_struct = load_handbook_struct(reference_forecast)

    # struct["rfinal"] is a vector of matrices indexed by the reference forecast
    # vintage, where each element is the revised final series starting from that
    # vintage's first forecast period. These elements of struct["rfinal"] form a
    # series of nesting subarrays, e.g.
    #
    #   mat_struct["rfinal"][2] = mat_struct["rfinal"][1][2:end, :]
    #   mat_struct["rfinal"][3] = mat_struct["rfinal"][2][2:end, :]
    #   etc.
    #
    # Hence we wish to use struct["rfinal"][1] to get the most periods of the
    # revised final data. (The same is true for first finals.)
    finals = if plot_settings[:realized_data] == :revisedfinal
        mat_struct["rfinal"][1]
    elseif plot_settings[:realized_data] == :firstfinal
        mat_struct["ffinal"][1]
    end

    # Note that we multiply by 4 below to get "annualized" numbers, which
    # are expected from the result of load_realized_data
    df = DataFrame(date = [DSGE.quartertodate(y, q) for (y, q) in plot_settings[:realtime_sample]],
                   obs_gdp         = finals[:, 1] * 4,
                   obs_gdpdeflator = finals[:, 2] * 4,
                   obs_nominalrate = finals[:, 3] * 4)
    return df
end

function load_handbook_reference_forecast(year::Int, quarter::Int,
                                          reference_forecast::Symbol,
                                          mat_struct::Dict{String, Any})
    # Forecasted dates
    horizons   = reference_forecast_horizons(reference_forecast)
    start_date = DSGE.quartertodate(year, quarter)
    end_date   = DSGE.iterate_quarters(start_date, horizons - 1)
    dates      = DSGE.quarter_range(start_date, end_date)
    df         = DataFrame(date = dates)

    # Forecasted values
    datestr = Dates.format(reference_forecast_vintage(year, quarter, reference_forecast), "dd-u-yyyy")
    forecast_index = findfirst(mat_struct["date"], datestr)
    if forecast_index == 0
        warn("$year-Q$quarter $(reference_forecast_longname(reference_forecast)) forecast missing")
        df[:obs_gdp]         = NaN
        df[:obs_gdpdeflator] = NaN
        df[:obs_nominalrate] = NaN
    else
        forecast = mat_struct["forecast"][forecast_index]

        if size(forecast, 1) < horizons
            # Pad with NaNs if fewer than `horizons` periods are reported
            n_missing_periods = horizons - size(forecast, 1)
            forecast = vcat(forecast, NaN*zeros(n_missing_periods, 3))
        elseif size(forecast, 1) > horizons
            # Keep only first `horizons` forecasted periods
            forecast = forecast[1:horizons, :]
        end

        # We multiply by 4 below to get "annualized" numbers, which are expected
        # from the result of load_handbook_reference_forecast
        df[:obs_gdp]         = forecast[:, 1] * 4
        df[:obs_gdpdeflator] = forecast[:, 2] * 4
        df[:obs_nominalrate] = forecast[:, 3] * 4
    end
    return df
end

function load_handbook_reference_forecast(year::Int, quarter::Int, reference_forecast::Symbol)
    println("Reading $(reference_forecast_longname(reference_forecast)) forecasts...")

    mat_struct = load_handbook_struct(reference_forecast)
    df = load_handbook_reference_forecast(year, quarter, reference_forecast, mat_struct)
    return df
end

function read_all_handbook_forecasts(reference_forecast::Symbol)
    println("Reading $(reference_forecast_longname(reference_forecast)) forecasts...")

    mat_struct = load_handbook_struct(reference_forecast)

    forecasts = OrderedDict{Tuple{Int, Int}, DataFrame}()
    for (y, q) in plot_settings[:realtime_sample]
        # Fill in this forecast's forecasted values
        forecasts[(y, q)] = load_handbook_reference_forecast(y, q, reference_forecast, mat_struct)
    end
    return forecasts
end
