### DATES AND VINTAGES

"""
```
reference_forecast_vintage(year, quarter, reference_forecast)
```

Returns the release date of the `reference_forecast` whose first forecasted
period was the given `year` and `quarter.

For Blue Chip forecasts (which are released monthly), which month's forecast is
used for the quarter depends on the constant `BLUECHIP_FORECAST_MONTH`. Note
also that if `BLUECHIP_FORECAST_MONTH == 1`, then the first forecasted period is
actually the *previous* quarter. (For example, the first forecasted quarter in
the January 2011 Blue Chip forecast is 2010-Q4.) This is not the case for other
values of `BLUECHIP_FORECAST_MONTH`, for which the first forecasted quarter is
the same quarter the forecast was released.
"""
function reference_forecast_vintage(year::Int, quarter::Int, reference_forecast::Symbol)
    if reference_forecast == :bluechip
        if BLUECHIP_FORECAST_MONTH == 1
            release_quarter = quarter % 4 + 1
            release_year = if release_quarter == 1
                year + 1
            else
                year
            end
        elseif BLUECHIP_FORECAST_MONTH in [2, 3]
            release_quarter = quarter
            release_year = year
        else
            error("Invalid BLUECHIP_FORECAST_MONTH: $BLUECHIP_FORECAST_MONTH")
        end
        release_month = 3*(release_quarter - 1) + BLUECHIP_FORECAST_MONTH
        release_day   = 10
    elseif reference_forecast == :greenbook
        error("We haven't figured out how to programmatically determine Greenbook vintages yet...")
    else
        error("Invalid reference forecast $reference_forecast")
    end

    return Dates.Date(release_year, release_month, release_day)
end

function vintage_to_date(vint::String)
    @assert length(vint) == 6
    yy = Meta.parse(vint[1:2])
    year = (yy >= 59 ? 1900 : 2000) + yy
    month = Meta.parse(vint[3:4])
    day   = Meta.parse(vint[5:6])
    return Dates.Date(year, month, day)
end

function estimation_vintage(reference_forecast::Symbol, vint::String)
    estimation_date = if reference_forecast == :bluechip
        date = vintage_to_date(vint)
        Dates.Date(Dates.year(date), 1, 10)
    elseif reference_forecast == :greenbook
        error("We haven't figured out how to programmatically determine Greenbook vintages yet...")
    else
        error("Invalid reference forecast $reference_forecast")
    end
    return Dates.format(estimation_date, "yymmdd")
end

function DSGE.quartertodate(year::Int, quarter::Int)
    DSGE.quartertodate("$year-Q$quarter")
end

function realized_forecast_horizons(year::Int, quarter::Int)
    # last_realized_quarter = DSGE.quartertodate(2017, 2)
    # Using a new last_realized_quarter
    last_realized_quarter = DSGE.quartertodate(2018, 3)
    potential_horizons = DSGE.subtract_quarters(last_realized_quarter, DSGE.quartertodate(year, quarter)) + 1
    return min(potential_horizons, REALTIME_FORECAST_HORIZONS)
end

function reference_forecast_horizons(reference_forecast::Symbol)
    if reference_forecast == :bluechip
        return 8
    elseif reference_forecast == :greenbook
        error("We haven't figured out how to programmatically determine Greenbook vintages yet...")
    else
        error("Invalid reference forecast $reference_forecast")
    end
end

Quarter(v::Number) = Dates.Month(3v)


## MODEL CONSTRUCTION

function realtime_spec(model::Symbol)
    if model == :Model510
        return "m510"
    elseif model == :Model557
        return "m557"
    elseif model == :SmetsWouters
        return "smets_wouters"
    elseif model == :Model805
        return "m805"
    elseif model == :Model904
        return "m904"
    elseif model == :Model990
        return "m990"
    elseif model == :Model1002
        return "m1002"
    elseif model == :Model1006
        return "m1006"
    elseif model == :Model1010
        return "m1010"
    elseif model == :Model1018
        return "m1018"
    elseif model == :Model1019
        return "m1019"
    elseif model == :Model1020
        return "m1020"
    elseif model == :Model1021
        return "m1021"
    elseif model == :Model1022
        return "m1022"
    else
        error("Invalid model $model")
    end
end

function realtime_unspec(m::AbstractModel)
    if m.spec == "m510"
        return :Model510
    elseif m.spec == "m557"
        return :Model557
    elseif m.spec == "an_schorfheide"
        return :AnSchorfheide
    elseif m.spec == "smets_wouters"
        return :SmetsWouters
    elseif m.spec == "smets_wouters_orig"
        return :SmetsWoutersOrig
    elseif m.spec == "m805"
        return :Model805
    elseif m.spec == "m904"
        return :Model904
    elseif m.spec == "m990"
        return :Model990
    elseif m.spec == "m1002"
        return :Model1002
    elseif m.spec == "m1006"
        return :Model1006
    elseif m.spec == "m1010"
        return :Model1010
    elseif m.spec == "m1018"
        return :Model1018
    elseif m.spec == "m1019"
        return :Model1019
    elseif m.spec == "m1020"
        return :Model1020
    elseif m.spec =="m1021"
        return :Model1021
    elseif m.spec =="m1022"
        return :Model1022
    else
        error("Invalid mspec $(m.spec)")
    end
end

function realtime_subspec(model::Symbol, subspec::String = "")
    if isempty(subspec)
        if model == :Model510
            return "ss11"
        elseif model == :Model557
            return "ss11"
        elseif model == :SmetsWouters
            return "ss1"
        elseif model == :Model805
            return "ss1"
        elseif model == :Model904
            return "ss10"
        elseif model == :Model990
            return "ss6"
        elseif model == :Model1002
            return "ss11"
        elseif model == :Model1006
            return "ss3"
        elseif model == :Model1010
            return "ss21"
        elseif model == :Model1018
            return "ss1"
        elseif model == :Model1019
            return "ss1"
        elseif model == :Model1020
            return "ss1"
        elseif model == :Model1021
            return "ss3"
        elseif model == :Model1022
            return "ss21"
        else
            error("Invalid model $model")
        end
    else
        return subspec
    end
end

function get_reference_forecast(m::AbstractModel)
    vint = vintage_to_date(data_vintage(m))
    y = Dates.year(date_forecast_start(m))
    q = Dates.quarterofyear(date_forecast_start(m))
    for reference_forecast in [:bluechip, :greenbook]
        if reference_forecast_vintage(y, q, reference_forecast) == vint
            return reference_forecast
        end
    end
    error("No reference forecast found for vintage $vint")
end


### DATA LOADING

function get_fred_mnemonics(m::AbstractModel)
    fred_series = parse_data_series(m)[:FRED]

    ind_corepce = something(findfirst(isequal(:PCEPILFE), fred_series), 0)
    ind_corepce > 0 && (fred_series[ind_corepce] = :JCXFE)

    ind_gdpdeflator = something(findfirst(isequal(:PDPCTPI), fred_series), 0)
    ind_gdpdeflator > 0 && (fred_series[ind_gdpdeflator] = :GDPDEF)

    return fred_series
end

function join_fred_series(df::DataFrame, series::FredSeries;
                          frequency::String = "q")
    series_id = Symbol(series.id)
    rename!(series.df, :value => series_id)
    if frequency == "q"
        map!(Dates.lastdayofquarter, series.df[:date], series.df[:date])
    elseif frequency == "m"
        map!(Dates.lastdayofmonth, series.df[:date], series.df[:date])
        normalize_lastdayofmonth!(series)
    end

    df = join(df, series.df[[:date,series_id]], on = :date, kind = :outer)
    return df
end

# Function for ensuring the types of the arrays comprising df are just Vector{Float64}
function enforce_concrete_typed_df_columns!(df::DataFrame)
    columns = df.colindex.names
    for col in columns
        @assert count(ismissing.(df[col])) == 0 "Column $col of df has missing entries. Cannot remove Missing union"
        if typeof(df[col]) == Vector{Union{Float64, Missings.Missing}}
            df[col] = Vector{Float64}(df[col])
        elseif typeof(df[col]) == Vector{Union{Dates.Date, Missings.Missing}}
            df[col] = Vector{Dates.Date}(df[col])
        end
    end
end

function clean_df!(df::DataFrame)
    sort!(df, :date)
    #DSGE.na2nan!(df)
    #enforce_concrete_typed_df_columns!(df)
    return df
end

function load_fred_data(vintaged_series::Vector{Symbol}, unvintaged_series::Vector{Symbol},
                        start_date::Dates.Date, end_date::Dates.Date, vintage_date::Dates.Date = Dates.Date(1);
                        frequency::String = "q",
                        verbose::Symbol = :low)

    # Check that vintage_date is provided if vintaged_series is nonempty
    if !isempty(vintaged_series) && vintage_date == Dates.Date(1)
        error("Must provide vintage_date if vintage_series is nonempty")
    end

    # Initialize DataFrame
    if frequency == "q"
        df = DataFrame(date = DSGE.quarter_range(start_date, end_date))
    elseif frequency == "m"
        df = DataFrame(date = month_range(start_date, end_date))
        normalize_lastdayofmonth!(df)
    else
        throw("Invalid frequency specified. Must be either quarterly `q` or monthly `m`.")
    end

    for s in vcat(vintaged_series, unvintaged_series)
        try
            series = if s in unvintaged_series
                # Fetch "unvintaged" series, aka series with vintage today
                if DSGE.VERBOSITY[verbose] >= DSGE.VERBOSITY[:high]
                    println(" * Fetching FRED series $s without vintage...")
                end
                get_data(fred, string(s); frequency=frequency,
                         observation_start=string(start_date),
                         observation_end=string(end_date),
                         vintage_dates=string(Dates.today()))
            else
                # Fetch vintaged series
                if DSGE.VERBOSITY[verbose] >= DSGE.VERBOSITY[:high]
                    println(" * Fetching FRED series $s at vintage $vintage_date...")
                end
                get_data(fred, string(s); frequency=frequency,
                         observation_start=string(start_date),
                         observation_end=string(end_date),
                         vintage_dates=string(vintage_date))
            end
            df = join_fred_series(df, series, frequency = frequency)
        catch ex
            @show ex
            isa(ex, InterruptException) && throw(ex)

            # Fill with NaNs if series can't be fetched
            if DSGE.VERBOSITY[verbose] >= DSGE.VERBOSITY[:high]
                warn(ex)
            end
            if DSGE.VERBOSITY[verbose] >= DSGE.VERBOSITY[:low]
                println(" * FRED series $s could not be fetched. Returning NaNs instead.")
            end
            df[s] = NaN
        end
    end

    return clean_df!(df)
end

# Convenience function
function load_fred_data(vintaged_series::Vector{Symbol}, start_date::Dates.Date, end_date::Dates.Date,
                        vintage_date::Dates.Date = Dates.Date(); frequency::String = "q",
                        verbose::Symbol = :low)

    # Check that vintage_date is provided if vintaged_series is nonempty
    if !isempty(vintaged_series) && vintage_date == Dates.Date()
        error("Must provide vintage_date if vintage_series is nonempty")
    end

    # Initialize DataFrame
    if frequency == "q"
        df = DataFrame(date = DSGE.quarter_range(start_date, end_date))
    elseif frequency == "m"
        df = DataFrame(date = month_range(start_date, end_date))
        normalize_lastdayofmonth!(df)
    else
        throw("Invalid frequency specified. Must be either quarterly `q` or monthly `m`.")
    end

    for s in vintaged_series
        try
            # Fetch vintaged series
            if DSGE.VERBOSITY[verbose] >= DSGE.VERBOSITY[:high]
                println(" * Fetching FRED series $s at vintage $vintage_date...")
            end
            series = get_data(fred, string(s); frequency=frequency,
                              observation_start=string(start_date),
                              observation_end=string(end_date),
                              vintage_dates=string(vintage_date))
            df = join_fred_series(df, series, frequency = frequency)
        catch ex
            isa(ex, InterruptException) && throw(ex)

            # Fill with NaNs if series can't be fetched
            if DSGE.VERBOSITY[verbose] >= DSGE.VERBOSITY[:high]
                warn(ex)
            end
            if DSGE.VERBOSITY[verbose] >= DSGE.VERBOSITY[:low]
                println(" * FRED series $s could not be fetched. Returning NaNs instead.")
            end
            df[s] = NaN
        end
    end

    return clean_df!(df)
end

function realtime_isvalid_data(m::AbstractModel, df::DataFrame)
    valid = true

    # Ensure that every series in m_series is present in df_series
    ant_obs = [Symbol("obs_nominalrate$i")::Symbol for i = 1:n_anticipated_shocks(m)]
    m_series = collect(keys(m.observable_mappings))
    m_series = setdiff(m_series, ant_obs)

    df_series = names(df)

    coldiff = setdiff(m_series, df_series)
    valid = valid && isempty(coldiff)
    if !isempty(coldiff)
        println("The following expected columns of 'df' are missing: $coldiff")
    end

    # Ensure the dates between date_presample_start and date_mainsample_end are contained.
    actual_dates = df[:date]

    start_date = date_presample_start(m)
    end_date   = date_mainsample_end(m)
    expected_dates = DSGE.quarter_range(start_date, end_date)
    datesdiff = setdiff(expected_dates, actual_dates)

    valid = valid && isempty(datesdiff)
    if !isempty(datesdiff)
        println("Dates of 'df' do not match expected.")
        println(datesdiff)
    end

    # Ensure that no series is all-NaN
    nan_series = Base.filter(col -> all(map(x -> ismissing(x) ? true : isnan(x), df[col])), setdiff(names(df), [:date]))
    valid = valid && isempty(nan_series)
    if !isempty(nan_series)
        println("The following series are all NaN: $nan_series")
    end

    return valid
end

function writetable_mkdir(filename::String, df::DataFrame; verbose::Symbol = :low)
    dir = dirname(filename)
    !isdir(dir) && mkdir(dir)
    CSV.write(filename, df)
    if DSGE.VERBOSITY[verbose] >= DSGE.VERBOSITY[:low]
        println("Saved $filename")
    end
    try
        run(`chmod g+rw $filename`)
    catch
        println("Didn't chmod g+rw $filename")
    end
end


### IO

function filestring(filestrs::OrderedDict)
    strs = [(string(k) * "=" * string(v))::String for (k, v) in filestrs]
    addl = join(strs, "_")
    !isempty(addl) && (addl = "_" * addl)
    return addl
end

strs = [:work, :raw, :tables, :figures]
fns = [Symbol(x, "path") for x in strs]
for (str, fn) in zip(strs, fns)
    @eval begin
        function $fn(model::Symbol, out_type::String, file_name::String = "";
                     subspec::String = "",
                     filestrs::OrderedDict = OrderedDict{Symbol, Any}(),
                     saveroot::String = SMC_DIR,
                     is_reference_forecast = false)

            if is_reference_forecast
                reference_forecast = model
                dirname = joinpath(saveroot, "output_data", string(reference_forecast), $(string(str)))
            else
                spec = realtime_spec(model)
                subspec = realtime_subspec(model, subspec)
                dirname = joinpath(saveroot, "output_data", spec, subspec, out_type, $(string(str)))
            end

            path = if isempty(file_name)
                dirname
            else
                base, ext = splitext(file_name)
                addl = filestring(filestrs)
                joinpath(dirname, base * addl * ext)
            end
            return path
        end
    end
end

function read_realtime_mb(model::Symbol, year::Int, quarter::Int,
                          reference_forecast::Symbol,
                          input_type::Symbol, cond_type::Symbol,
                          product::Symbol, class::Symbol;
                          subspec::String = "",
                          enforce_zlb::Symbol = :default,
                          forecast_string::String = "")

    # Handle equivalent (EST_SPEC, FCAST_SPEC) pairs before 2009
    est, fcast = if (EST_SPEC, FCAST_SPEC) in [(1, 1), (4, 1)] && (year, quarter) < (2009, 1)
        4, 8
    else
        EST_SPEC, FCAST_SPEC
    end

    filestrs = OrderedDict{Symbol, Any}()
    filestrs[:cond] = cond_type
    !isempty(forecast_string) && (filestrs[:fcid] = forecast_string)
    filestrs[:est] = est
    filestrs[:fcast] = fcast
    filestrs[:para] = input_type
    filestrs[:vint] = Dates.format(reference_forecast_vintage(year, quarter, reference_forecast), "yymmdd")

    if product == :forecast && enforce_zlb == :default
        # Read in unbounded forecast means, bounded forecast bands
        fn1 = workpath(model, "forecast", "mb" * "bddforecast" * string(class) * ".jld",
                       subspec = subspec, filestrs = filestrs)
        fn2 = workpath(model, "forecast", "mb" * "forecast" * string(class) * ".jld",
                       subspec = subspec, filestrs = filestrs)
        return read_bdd_and_unbdd_mb(fn1, fn2)

    else
        if product == :forecast && enforce_zlb == :true
            # Read in bounded forecast means and bands
            product = :bddforecast
        end

        fn = workpath(model, "forecast", "mb" * string(product) * string(class) * ".jld",
                      subspec = subspec, filestrs = filestrs)
        return read_mb(fn)
    end
end

function read_all_realtime_mbs(model::Symbol, reference_forecast::Symbol,
                               input_type::Symbol, cond_type::Symbol,
                               product::Symbol, class::Symbol;
                               subspec::String = "",
                               enforce_zlb::Symbol = :default)

    subspec = realtime_subspec(model, subspec)
    if product == :hist
        println("Reading $model $subspec $class histories...")
    elseif product == :forecast
        println("Reading $model $subspec $class forecasts...")
    end
    mbs = OrderedDict{Tuple{Int, Int}, MeansBands}()
    for (y, q) in plot_settings[:realtime_sample]
        try
            mbs[(y, q)] = read_realtime_mb(model, y, q, reference_forecast, input_type, cond_type,
                                           product, class, enforce_zlb = enforce_zlb)
        catch ex
            isa(ex, InterruptException) && throw(ex)
            warn("$y-Q$q $model $product missing")
        end
    end
    return mbs
end

function read_all_realtime_forecasts(model::Symbol, reference_forecast::Symbol,
                                     input_type::Symbol, cond_type::Symbol;
                                     subspec::String = "",
                                     enforce_zlb::Symbol = :default)

    subspec = realtime_subspec(model, subspec)
    println("Reading $model $subspec forecasts...")

    # Initialize dictionary
    forecasts = OrderedDict{Tuple{Int, Int}, DataFrame}()
    for (y, q) in plot_settings[:realtime_sample]
        try
            cols = vcat([:date], realtime_vars(model))
            mb = read_realtime_mb(model, y, q, reference_forecast, input_type, cond_type,
                                  :forecast, :obs, enforce_zlb = enforce_zlb)
            forecasts[(y, q)] = mb.means[cols]
        catch ex
            isa(ex, InterruptException) && throw(ex)
            warn(ex)
            warn("$y-Q$q $model forecast missing")
        end
    end
    return forecasts
end

### FORECAST

function realtime_forecast_input_file!(m::AbstractModel, input_type::Symbol,
                                       est_override::String = ""; data_spec::Int = 0)

    if isempty(est_override)
        est_file = get_forecast_input_file(m, input_type)

        # Replace forecast vintage with estimation vintage
        reference_forecast = get_reference_forecast(m)
        est_file = replace(est_file, data_vintage(m), estimation_vintage(reference_forecast, data_vintage(m)))

        # Replace actual subspec with default subspec
        model = realtime_unspec(m)
        est_file = replace(est_file, m.subspec, realtime_subspec(model))

        # Remove FCAST_SPEC
       # est_file = replace(est_file, "_fcast=$FCAST_SPEC", "")
    else
        est_file = est_override
    end

    overrides = forecast_input_file_overrides(m)
    overrides[input_type] = est_file

   #= if data_spec == 2
        if data_vintage(m) in ["090110", "100110", "110110", "120110", "130110", "140110", "150110"]
        overrides[input_type] = replace(est_file, "est=1" => "est=4")
        end
    end =#

end


### ANALYSIS

function realtime_vars(model::Symbol)
    if model == :greenbook
        return [:obs_gdp, :obs_gdpdeflator]
    elseif model == :Model510
        return [:obs_gdp, :obs_corepce, :obs_nominalrate]
    elseif model in [:bluechip, :SmetsWouters, :Model805, :Model904]
        return [:obs_gdp, :obs_gdpdeflator, :obs_nominalrate]
    elseif model in [:Model990, :Model1002, :Model1006, :Model1010,
                     :Model1018, :Model1019, :Model1020, :Model1021,
                     :Model1022]
        return [:obs_gdp, :obs_gdpdeflator, :obs_corepce, :obs_nominalrate]
    else
        error("Invalid model $model")
    end
end

"""
```
revtrans_to_rmse_units(y, var)
```

This function takes \"reverse transformed\" series into the following units in
which we compute RMSEs:

- `:obs_gdp`: quarterly log growth rates, `100*log(Y_t - Y_{t-1})`, where `Y_t` is
  aggregate real GDP
- `:obs_gdpdeflator` and `:obs_corepce`: quarterly log growth rates,
  `100*log(P_t - P_{t-1})`, where `P_t` is (GDP or core PCE) price index
- `:obs_nominalrate`: quarterly percent, `R_t` / 4, where `R_t` is nominal
  annual FFR
"""
function revtrans_to_rmse_units(y::AbstractVector{Float64}, var::Symbol;
                                from_4q::Bool = false, to_4q::Bool = false)
    if var == :obs_nominalrate
        if to_4q
            return y
        else
            return y / 4
        end
    elseif var in [:obs_gdp, :obs_gdpdeflator, :obs_corepce]
        if !from_4q && !to_4q
            # Q/Q percent annualized to Q/Q log growth rates
            return 100*log.((y/100 .+ 1).^(1/4))
        elseif !from_4q && to_4q
            # Q/Q percent annualized to 4Q log growth rates
            log_growth_rates = 100*log.((y/100 .+ 1).^(1/4))
            tmp = vcat([NaN, NaN, NaN], log_growth_rates)
            return tmp[1:end-3] + tmp[2:end-2] + tmp[3:end-1] + tmp[4:end]
        elseif from_4q && to_4q
            # 4Q percent to 4Q log growth rates (SEP, annual SPF)
            return 100*log.(y/100 .+ 1)
        else
            error("This case (from_4q = $from_4q, to_4q = $to_4q) should never happen")
        end
    else
        error("Invalid variable $var")
    end
end

function reverse_transform_naive(model::Symbol, reference_forecast::Symbol,
                                 comp_forecasts::OrderedDict{Tuple{Int64, Int64}, DataFrame};
                                 years::UnitRange = 2011:2016, quarters::UnitRange = 1:4,
                                 subspec::String = "")
    for start_year in years
        for start_quarter in quarters
            if start_year == 2016 && start_quarter > 1
                break
            end
            # Setup model and data
            m = prepare_realtime_model(model, start_year, start_quarter, reference_forecast, fcast_settings,
                                       subspec = subspec)

            obs_map = m.observable_mappings

            population_data, population_forecast = DSGE.load_population_growth(m, verbose = :none)

            # Read in forecast metadata
            metadata = DSGE.get_mb_metadata(m, :full, :full, :forecastobs; forecast_string = "")

            date_list      = collect(keys(metadata[:date_inds]))
            variable_names = collect(keys(metadata[:indices]))
            pop_growth     = DSGE.get_mb_population_series(:forecast, population_data, population_forecast, date_list)

            gdp = comp_forecasts[(start_year, start_quarter)][:obs_gdp]
            gdp_deflator = comp_forecasts[(start_year, start_quarter)][:obs_gdpdeflator]
            nominal_rate = comp_forecasts[(start_year, start_quarter)][:obs_nominalrate]
            comp_forecasts[(start_year, start_quarter)][:obs_gdp] = obs_map[:obs_gdp].rev_transform(gdp, pop_growth[1:length(gdp)])
            comp_forecasts[(start_year, start_quarter)][:obs_gdpdeflator] = obs_map[:obs_gdpdeflator].rev_transform(gdp_deflator)
            comp_forecasts[(start_year, start_quarter)][:obs_nominalrate] = obs_map[:obs_nominalrate].rev_transform(nominal_rate)
        end
    end
    return comp_forecasts
end

### PLOTTING

function load_initial_forecast_values(reference_forecast::Symbol, var::Symbol)
    sample_size = length(plot_settings[:realtime_sample])
    initial_values = NaN*zeros(sample_size)
    for (i, (y, q)) in enumerate(plot_settings[:realtime_sample])
        # Load untransformed data
        vint = Dates.format(reference_forecast_vintage(y, q, reference_forecast), "yymmdd")
        m = prepare_realtime_model(:SmetsWouters, y, q, reference_forecast)
        untransformed = load_realtime_data(m, reference_forecast)

        # Reverse transform
        transformed = reverse_transform(m, untransformed, :obs)

        # Initial forecast value is last (transformed) historical value
        initial_values[i] = transformed[end, var]
    end
    return initial_values
end

function plot_titles!(p::Plots.Plot, var::Symbol;
                      xlabel::Bool = false,
                      ylabel::Bool = true,
                      quarterly::Bool = false,
                      fourquarter::Bool = false)
    # Title
    if var == :obs_gdp
        title!(p, "Real GDP Growth")
    elseif var == :obs_gdpdeflator
        title!(p, "GDP Deflator Inflation")
    elseif var == :obs_corepce
        title!(p, "Core PCE Inflation")
    elseif var == :obs_nominalrate
        title!(p, "Nominal FFR")
    end

    # Y-axis label
    if ylabel
        if var in [:obs_gdp, :obs_gdpdeflator, :obs_corepce]
            if quarterly
                yaxis!(p, "Percent Q/Q")
            elseif fourquarter
                yaxis!(p, "Percent 4Q")
            else
                yaxis!(p, "Percent Q/Q Annualized")
            end
        elseif var == :obs_nominalrate
            if quarterly
                yaxis!(p, "Percent (Quarterly)")
            elseif fourquarter
                yaxis!(p, "Percent (4Q)")
            else
                yaxis!(p, "Percent (Annualized)")
            end
        end
    end

    # X-axis label
    if xlabel
        if fourquarter
            xaxis!(p, "Year")
        else
            xaxis!(p, "Quarter")
        end
    end

    return p
end

function reference_forecast_longname(reference_forecast::Symbol)
    if reference_forecast == :bluechip
        return "Blue Chip"
    elseif reference_forecast == :greenbook
        return "Greenbook"
    elseif reference_forecast == :staff
        return "NY Fed Staff"
    else
        error("Invalid reference forecast $reference_forecast")
    end
end

function reference_forecast_color(reference_forecast::Symbol)
    if reference_forecast == :bluechip
        return :blue
    elseif reference_forecast == :greenbook
        return :green
    else
        error("Invalid reference forecast $reference_forecast")
    end
end

function reference_forecast_palette(reference_forecast::Symbol)
    if reference_forecast == :bluechip
        return :blues
    elseif reference_forecast == :greenbook
        return :greens
    else
        error("Invalid reference forecast $reference_forecast")
    end
end

function standardize_forecast_ylims(year::Int, quarter::Int,
                                    models::Vector{Symbol}, reference_forecast::Symbol,
                                    input_type::Symbol, cond_type::Symbol;
                                    start_date::Dates.Date = DSGE.iterate_quarters(DSGE.quartertodate(year, quarter), -8),
                                    end_date::Dates.Date = DSGE.iterate_quarters(DSGE.quartertodate(year, quarter),
                                                                           REALTIME_FORECAST_HORIZONS - 1),
                                    enforce_zlb::Symbol = :default,
                                    plot_bands::Bool = true)
    hist_mbs  = OrderedDict{Symbol, MeansBands}()
    fcast_mbs = OrderedDict{Symbol, MeansBands}()
    plot_range = DSGE.quarter_range(start_date, end_date)

    for model in models
        try
            hist_mbs[model] = read_realtime_mb(model, year, quarter, reference_forecast, input_type, cond_type,
                                               :hist, :obs, enforce_zlb = enforce_zlb)
            fcast_mbs[model] = read_realtime_mb(model, year, quarter, reference_forecast, input_type, cond_type,
                                                :forecast, :obs, enforce_zlb = enforce_zlb)
        catch
            warn("$year-Q$quarter $model history and/or forecast missing")
        end
    end

    ylims = Dict{Symbol, NTuple{2, Number}}()
    output_vars = union(map(realtime_vars, models)...)

    for var in output_vars
        lb = 100
        ub = -100
        for model in models
            if var in realtime_vars(model) && haskey(hist_mbs, model) && haskey(fcast_mbs, model)
                if plot_bands
                    hist_df  = hist_mbs[model].bands[var]
                    fcast_df = fcast_mbs[model].bands[var]
                    lcol     = Symbol("90.0% LB")
                    ucol     = Symbol("90.0% UB")
                else
                    hist_df  = hist_mbs[model].means
                    fcast_df = fcast_mbs[model].means
                    lcol     = var
                    ucol     = var
                end

                hist_lb  = minimum(hist_df[findin(hist_df[:date], plot_range), lcol])
                fcast_lb = minimum(fcast_df[findin(fcast_df[:date], plot_range), lcol])

                hist_ub  = maximum(hist_df[findin(hist_df[:date], plot_range), ucol])
                fcast_ub = maximum(fcast_df[findin(fcast_df[:date], plot_range), ucol])

                lb = min(lb, hist_lb, fcast_lb)
                ub = max(ub, hist_ub, fcast_ub)
            end
        end

        lb = floor(lb)
        ub = ceil(ub)

        ylims[var] = (lb, ub)
    end

    return ylims
end

function standardize_system_ylims(output_var::Symbol, reference_forecast::Symbol;
                                  start_date::Dates.Date = Dates.Date(),
                                  end_date::Dates.Date = Dates.Date(),
                                  enforce_zlb::Symbol = :default)

    models = system_models()
    years_months = collect(keys(models))

    lb = 100
    ub = -100
    for year_month in years_months

        if year_month > (2016, 4)
            break
        end

        for cond_type in [:semi, :full]
            # Set date variables
            year, month = year_month
            quarter_date = system_first_forecast_quarter(year, month)
            forecast_year         = Dates.year(quarter_date)
            forecast_quarter      = Dates.quarterofyear(quarter_date)

            # Setting start and end dates for plotting
            start_date =
            start_date == Dates.Date() ?
            DSGE.iterate_quarters(DSGE.quartertodate(forecast_year, forecast_quarter), -8) : start_date
            end_date =
            end_date == Dates.Date() ?
            DSGE.iterate_quarters(DSGE.quartertodate(forecast_year, forecast_quarter), REALTIME_FORECAST_HORIZONS - 1) : end_date

            # Load forecasts and realized values
            system_all = load_system_forecast(year, month, cond_type = cond_type, forecast_only = false)
            realized       = load_realized_data(reference_forecast)
            realized       = realized[realized[:date] .<= end_date, :]
            spf = load_spf_forecast(forecast_year, forecast_quarter)
            ref = load_reference_forecast(forecast_year, forecast_quarter, reference_forecast)

            # Find lower and upper bounds
            system_lb   = minimum(system_all[output_var][.!isnan.(system_all[output_var])])
            realized_lb = minimum(realized[output_var][.!isnan.(realized[output_var])])
            spf_lb      = minimum(spf[output_var][.!isnan.(spf[output_var])])
            ref_lb      = output_var != :obs_corepce ?
            minimum(ref[output_var][.!isnan.(ref[output_var])]) : 100

            system_ub   = maximum(system_all[output_var][.!isnan.(system_all[output_var])])
            realized_ub = maximum(realized[output_var][.!isnan.(realized[output_var])])
            spf_ub      = maximum(spf[output_var][.!isnan.(spf[output_var])])
            ref_ub      = output_var != :obs_corepce ?
            maximum(ref[output_var][.!isnan.(ref[output_var])]) : -100

            lb = min(lb, system_lb, realized_lb, spf_lb, ref_lb)
            ub = max(ub, system_ub, realized_ub, spf_ub, ref_ub)
        end
    end

    lb = floor(lb)
    ub = ceil(ub)

    return (lb, ub)
end

function iterate_all_quarters(quarter_list::Vector{Tuple{Int, Int}})
    new_quarter_list = Vector{Tuple{Int, Int}}(length(quarter_list))
    for (i, year_quarter) in enumerate(quarter_list)
        year = year_quarter[1]
        quarter = year_quarter[2]
        new_year_quarter = iterate_quarters(DSGE.quartertodate("$year-Q$quarter"), 1)
        new_year = Dates.year(new_year_quarter)
        new_quarter = DSGE.datetoquarter(new_year_quarter)
        new_quarter_list[i] = (new_year, new_quarter)
    end
    return new_quarter_list
end

function month_range(start_date::Dates.Date,
                     end_date::Dates.Date;
                     lastdayofmonth::Bool = true)
    if lastdayofmonth
        normalize_lastdayofmonth(Dates.lastdayofmonth.(collect(start_date:Dates.Month(1):end_date)))
    else
        # Default behavior enforces that the increment is exactly a month
        # so if start_date and end_date are different days of the month
        # then the range will be based on the day of the month specified in start_date
        return collect(start_date:Dates.Month(1):end_date)
    end
end

# Normalize date format to be the 30th if it's a non-February month
# to follow the convention that is defaulted by the Dates
# range option: d1:Dates.month(1):d2. Thankfully, it handles the
# February months (with leap days) correctly
function normalize_lastdayofmonth!(series::FredData.FredSeries)
    normalize_lastdayofmonth!(series.df)
end

function normalize_lastdayofmonth!(df::DataFrame)
    df[:date] = normalize_lastdayofmonth(df[:date])
end

function normalize_lastdayofmonth(v::Vector{Date})
    v_new = copy(v)
    for (i, date) in enumerate(v)
        v_new[i] =
            if Dates.day(date) == 31
                Date(Dates.year(date), Dates.month(date), 30)
            else
                date
            end
    end
    return v_new
end
