function load_eg_wages(vint::String, reference_forecast::Symbol,
                       year::Int, quarter::Int; verbose::Symbol = :low)

    # Dates
    vint_date = vintage_to_date(vint)
    ref_date = lowercase(Dates.monthabbr(vint_date)) * string(Dates.year(vint_date))[3:end]
    start_date = DSGE.quartertodate(1959, 2)
    end_date   = DSGE.iterate_quarters(DSGE.quartertodate(year, quarter), -1)

    # Initialize new DataFrame
    df = DataFrame(date = DSGE.quarter_range(start_date, end_date), COMPNFB = NaN)

    # Read file
    datadir = joinpath(SMC_DIR, "save/input_data", "data")
    filename = joinpath(datadir, "edge_gurkaynak", string(reference_forecast), "sw" * ref_date * "labor.txt")
    if DSGE.VERBOSITY[verbose] >= DSGE.VERBOSITY[:low]
        println(" * Filling in COMPNFB using $filename...")
    end

    lines = []
    try
        lines = open(filename) do file
            readlines(file)
        end
    catch ex
        if DSGE.VERBOSITY[verbose] >= DSGE.VERBOSITY[:high]
            warn(ex)
        end
        if DSGE.VERBOSITY[verbose] >= DSGE.VERBOSITY[:low]
            println(" * COMPNFB could not be filled in from $filename. Returning NaNs instead.")
        end
        return df
    end

    # Parse file
    for line in lines
        split_line = split(line)
        # Only parse lines that contain data (i.e. 5 columns)
        if length(split_line) == 5
            # split_line[1] is the observation date in YYYY.Q format
            obs_year    = string(split_line[1][1:4])
            obs_quarter = string(split_line[1][end])
            obs_date    = Dates.lastdayofquarter(Dates.Date(parse(Int, obs_year), 3*parse(Int, obs_quarter)))

            # split_line[3] is the wage series
            try
                obs_wages = parse(Float64,split_line[3])
                df[df[:date] .== obs_date, :COMPNFB] = obs_wages
            catch ex
                isa(ex, InterruptException) && throw(ex)
            end
        end
    end

    return clean_df!(df)
end

function load_nonfred_data(vint::String, year::Int, quarter::Int;
                           verbose::Symbol = :low)

    # Dates
    start_date = DSGE.quartertodate(1959, 2)
    end_date   = DSGE.iterate_quarters(DSGE.quartertodate(year, quarter), -1)

    df = DataFrame(date = DSGE.quarter_range(start_date, end_date))

    filepath = joinpath(SMC_DIR, "save/input_data/raw", "dlx.csv")
    if DSGE.VERBOSITY[verbose] >= DSGE.VERBOSITY[:low]
        println("Reading unvintaged series from $filepath...")
    end
    series = CSV.read(filepath)
    DSGE.format_dates!(:date, series)

    # For each file, truncate the series at the quarter before the current quarter
    series = series[start_date .<= series[:, :date] .<= end_date, :]
    df = join(df, series, on = :date, kind = :outer)

    return clean_df!(df)
end

function load_realtime_levels(m::AbstractModel, reference_forecast::Symbol,
                              year::Int, quarter::Int; verbose::Symbol = :none)

    # Dates
    vint       = data_vintage(m)
    vint_date  = vintage_to_date(vint)
    start_date = DSGE.quartertodate(1959, 2)
    end_date   = DSGE.iterate_quarters(DSGE.quartertodate(year, quarter), -1)

    # Load FRED data
    if DSGE.VERBOSITY[verbose] >= DSGE.VERBOSITY[:low]
        println("Loading FRED data...")
    end
    fred_series = get_fred_mnemonics(m)
    vintaged_series   = [:GDP, :GDPDEF, :AWHNONAG, :CE16OV, :COMPNFB, :JCXFE,
                         :PCE, :FPI, :GDI, :COE, :CPIAUCSL]
    unvintaged_series = [:CNP16OV, :DFF, :BAA, :AAA, :BAMLC8A0C15PYEY, :GS10, :GS20, :GS30,
                         :THREEFYTP10, :TOTLQ, :LTGOVTBD]
    fred_df = load_fred_data(intersect(fred_series, vintaged_series),
                             intersect(fred_series, unvintaged_series),
                             start_date, end_date, vint_date,
                             verbose = verbose)

    # If necessary (if FRED PCE/GDI vintages missing for this vintage), use
    # earliest available FRED vintage
    for (mnemonic, vintage) in zip([:JCXFE, :GDI], [Dates.Date(1999, 7, 29), Dates.Date(2012, 12, 20)])
        if mnemonic in names(fred_df) && all(isnan.(fred_df[mnemonic]))
            if DSGE.VERBOSITY[verbose] >= DSGE.VERBOSITY[:low]
                println(" * Filling in $mnemonic using earliest available FRED vintage ($vintage)...")
            end
            new_df = load_fred_data([mnemonic], Symbol[], start_date, end_date,
                                    vintage, verbose = verbose)
            delete!(fred_df, mnemonic)
            fred_df = join(fred_df, new_df, on = :date, kind = :outer)
        end
    end

    # If necessary (if FRED wages missing for this vintage), load wages from
    # Edge-Gurkaynak
    if :COMPNFB in names(fred_df) && all(isnan.(fred_df[:COMPNFB]))
        wage_df = load_eg_wages(vint, reference_forecast, year, quarter, verbose = verbose)
        deletecols!(fred_df, :COMPNFB)
        fred_df = join(fred_df, wage_df, on = :date, kind = :outer)
    end

    # Load non-FRED data
    nonfred_df = load_nonfred_data(vint, year, quarter, verbose = verbose)

    df = join(fred_df, nonfred_df, on = :date, kind = :outer)
    return clean_df!(df)
end

function load_realtime_population_growth(vint::String,
                                         year::Int, quarter::Int,
                                         settings::Dict{Symbol, Any};
                                         try_disk::Bool = true,
                                         save::Bool = true,
                                         verbose::Symbol = :low)

    data_savepath = joinpath(SMC_DIR, "save/input_data/raw", "population_data_levels_$vint.csv")
    forecast_savepath = joinpath(SMC_DIR, "save/input_data/raw", "population_forecast_$vint.csv")
    population_mnemonic = :CNP16OV

    reload_data = true
    if try_disk
        try
            # Read saved population data
            if DSGE.VERBOSITY[verbose] >= DSGE.VERBOSITY[:low]
                println("Reading $data_savepath...")
            end
            data = CSV.read(data_savepath)
            DSGE.format_dates!(:date, data)
            clean_df!(data)

            # Read saved population forecast
            if DSGE.VERBOSITY[verbose] >= DSGE.VERBOSITY[:low]
                println("Reading $forecast_savepath...")
            end
            forecast = CSV.read(forecast_savepath)
            DSGE.format_dates!(:date, forecast)
            clean_df!(forecast)
            rename!(forecast, :POPULATION => population_mnemonic)

            reload_data = false
        catch ex
            if isa(ex, InterruptException)
                throw(ex)
            else
                if DSGE.VERBOSITY[verbose] >= DSGE.VERBOSITY[:low]
                    @warn ex
                    println("Attempting to reload population data and forecast...")
                end
            end
        end
    end

    if reload_data
        forecast_start = DSGE.quartertodate(year, quarter)

        ## Population data

        # Fetch from FRED
        start_date = DSGE.quartertodate(1959, 2)
        end_date   = DSGE.iterate_quarters(forecast_start, -1)
        data       = load_fred_data(Symbol[], [population_mnemonic], start_date, end_date, verbose = verbose)

        # Save levels (for computing means and bands)
        if save
            writetable_mkdir(data_savepath, data, verbose = verbose)
        end

        ## Population "forecast", a.k.a. REALTIME_FORECAST_HORIZONS quarters of
        ## realized population as of today

        # Fetch from FRED
        start_date = forecast_start
        end_date   = DSGE.iterate_quarters(start_date, realized_forecast_horizons(year, quarter) - 1)
        forecast   = load_fred_data(Symbol[], [population_mnemonic], start_date, end_date, verbose = verbose)

        # Save levels (for computing means and bands)
        if save
            rename!(forecast, population_mnemonic => :POPULATION)
            writetable_mkdir(forecast_savepath, forecast, verbose = verbose)
            rename!(forecast, :POPULATION => population_mnemonic)
        end
    end

    ## HP filter over history and "forecast"
    if DSGE.VERBOSITY[verbose] >= DSGE.VERBOSITY[:high] && settings[:hpfilter_population]
        println("HP filtering population...")
    end
    data, forecast = DSGE.transform_population_data(data, forecast, population_mnemonic,
                                                    use_hpfilter = settings[:hpfilter_population])
    if settings[:hpfilter_population]
        new_mnemonics = [:filtered_population, :filtered_population_growth, :unfiltered_population_growth]
        old_mnemonics = [:filtered_population_recorded, :dlfiltered_population_recorded, :dlpopulation_recorded]
    else
        new_mnemonics = [:unfiltered_population_growth]
        old_mnemonics = [:dlpopulation_recorded]
    end
    rename!(data, zip(old_mnemonics, new_mnemonics))
    clean_df!(data)

    if settings[:hpfilter_population]
        old_mnemonics = [:filtered_population_forecast, :dlfiltered_population_forecast, :dlpopulation_forecast]
    else
        old_mnemonics = [:dlpopulation_forecast]
    end
    rename!(forecast, zip(old_mnemonics, new_mnemonics))
    clean_df!(forecast)

    return data, forecast
end

function transform_realtime_data(m::AbstractModel, levels::DataFrame, population_growth::DataFrame,
                                 reference_forecast::Symbol; verbose::Symbol = :low)

    # We usually use the monthly core PCE index (PCEPILFE) and the GDP
    # chain-type price index (GDPCTPI) series, so the model object expects those
    # mnemonics. However, the quarterly core PCE index (JCXFE) and GDP deflator
    # (GDPDEF) have vintages going back further, so we load that in the realtime
    # project instead.
    haskey(levels, :JCXFE)  && rename!(levels, :JCXFE => :PCEPILFE)
    # MDC: Commenting out because we have changed from using the GDPCTPI to
    # solely relying on GDPDEF.
    # haskey(levels, :GDPDEF) && rename!(levels, :GDPDEF => :GDPCTPI)

    # Join levels and population growth tables
    levels = join(levels, population_growth, on = :date, kind = :outer)

    # Apply transformations to each series (except interest rate expectations)
    transformed = DataFrame()
    transformed[:date] = levels[:date]

    data_transforms = collect_data_transforms(m)
    ant_obs = [Symbol("obs_nominalrate$i") for i = 1:n_anticipated_shocks(m)]

    for series in setdiff(keys(data_transforms), ant_obs)
        if DSGE.VERBOSITY[verbose] >= DSGE.VERBOSITY[:high]
            println("Transforming series $series...")
        end
        f = data_transforms[series]
        transformed[series] = f(levels)
    end

    sort!(transformed, :date)

    # Keep only dates in sample
    start_date = date_presample_start(m)
    end_date   = date_mainsample_end(m)
    transformed = transformed[start_date .<= transformed[:date] .<= end_date, :]

    return transformed
end

function load_rate_expectations_data(m::AbstractModel, df::DataFrame, settings::Dict{Symbol, Any};
                                     verbose::Symbol = :low)

    if settings[:rate_expectations_source] == :bluechip
        if DSGE.VERBOSITY[verbose] >= DSGE.VERBOSITY[:low]
            println("Conditioning on Blue Chip rate expectations...")
        end

        if !settings[:rate_expectations_post_liftoff]
            error("settings[:rate_expectations_post_liftoff] = false not implemented for settings[:rate_expectations_source] = :bluechip")
        end

        # Initialize columns with NaNs
        for h = 1:6
            df[Symbol("obs_nominalrate$h")] = NaN
        end

        for date in DSGE.quarter_range(date_zlb_start(m), df[end, :date])
            # Load Blue Chip forecast
            y, q = Dates.year(date), Dates.quarterofyear(date)
            ref = load_reference_forecast(y, q, :bluechip)

            # Find corresponding quarter in df
            df_date_ind = something(findfirst(isequal(date), df[:date]), 0)

            for h = 1:6
                # Suppose (y, q) = (2009, 4). Then load_reference_forecast loads
                # the January 2010 Blue Chip forecast, whose first forecasted
                # quarter (first row) is 2009-Q4. The observations we want to
                # put in df[:obs_nominalrate$h] are those from 2010-Q1 (second
                # row) on, so we use ref[h+1, :obs_nominalrate]

                # If necessary, divide by 4 to go from annualized to quarterly
                # rate expectations
                df[df_date_ind, Symbol("obs_nominalrate$h")] =
                    if realtime_unspec(m) == :Model510
                        # Model 510 uses annualized interest rates
                        ref[h+1, :obs_nominalrate]
                    else
                        # Other models use quarterly interest rates
                        ref[h+1, :obs_nominalrate] / 4
                    end
            end
        end

    elseif settings[:rate_expectations_source] == :ois
        if DSGE.VERBOSITY[verbose] >= DSGE.VERBOSITY[:low]
            println("Conditioning on OIS rate expectations...")
        end

        # Initialize df columns with NaNs
        for h = 1:6
            df[Symbol("obs_nominalrate$h")] = NaN
        end

        # Load all OIS data
        ois_file = settings[:rate_expectations_post_liftoff] ? "ois_170615.csv" : "ois.csv"
        filepath = joinpath(SMC_DIR, "save/input_data", "data", ois_file)
        ref = CSV.read(filepath)
        DSGE.format_dates!(:date, ref)

        for date in DSGE.quarter_range(date_zlb_start(m), date_mainsample_end(m))
            # Find quarter in ref and df
            df_date_ind = something(findfirst(isequal(date), df[:date]), 0)
            ref_date_ind = something(findfirst(isequal(date), ref[:date]), 0)
            if ref_date_ind > 0
                for h = 1:6
                    # If necessary, mulitply by 4 to go from quarterly to
                    # annualized rate expectations
                    df[df_date_ind, Symbol("obs_nominalrate$h")] =
                        if realtime_unspec(m) == :Model510
                            # Model 510 uses annualized interest rates
                            ref[ref_date_ind, Symbol("ant$h")] * 4
                        else
                            # Other models use quarterly interest rates
                            ref[ref_date_ind, Symbol("ant$h")]
                        end
                end
            else
                if DSGE.VERBOSITY[verbose] >= DSGE.VERBOSITY[:low]
                    warn("OIS rate expectations not found for $date, filled with NaN")
                end
            end
        end

    elseif settings[:rate_expectations_source] == :none
        nothing

    else
        error("Invalid settings[:rate_expectations_source]: $(settings[:rate_expectations_source])")
    end

    return df
end

function load_semiconditional_data(m::AbstractModel, year::Int, quarter::Int;
                                   verbose::Symbol = :none)
    cond_date = DSGE.quartertodate(year, quarter)
    semicond_series = [:DFF, :BAA, :AAA, :BAMLC8A0C15PYEY, :GS10, :GS20, :GS30, :THREEFYTP10, :FYCCZA]

    # Load financial data (except long rate) from FRED
    unvintaged_series = intersect(semicond_series, parse_data_series(m)[:FRED])
    if DSGE.VERBOSITY[verbose] >= DSGE.VERBOSITY[:low]
        println(" * Loading semiconditional $unvintaged_series from FRED...")
    end
    levels = load_fred_data(Symbol[], unvintaged_series, cond_date, cond_date, verbose = verbose)

    # Load long rate from CSV
    filepath = joinpath(SMC_DIR, "input_data", "data", "longrate.csv")
    if DSGE.VERBOSITY[verbose] >= DSGE.VERBOSITY[:low]
        println(" * Reading semiconditional FYCCZA from $filepath...")
    end
    series = CSV.read(filepath)
    DSGE.format_dates!(:date, series)
    levels[:FYCCZA] = series[series[:date] .== cond_date, :FYCCZA]

    # Transform semiconditional observables
    transformed = DataFrame()
    transformed[:date] = levels[:date]

    data_transforms = collect_data_transforms(m)

    ant_obs = [Symbol("obs_nominalrate$h")::Symbol for h = 1:n_anticipated_shocks(m)]
    for series in setdiff(cond_semi_names(m), ant_obs)
        if DSGE.VERBOSITY[verbose] >= DSGE.VERBOSITY[:high]
            println("Transforming series $series...")
        end
        f = data_transforms[series]
        transformed[series] = f(levels)
    end

    sort!(transformed, :date)
    return transformed
end

function untransform(model::Symbol, var::Symbol, y::Float64, pop::Float64)
    if var == :obs_gdp
        if model == :Model510
            return 100. * (log.(y/100 + 1.) .- 4.0*pop/100)
        else
            return 100. * log.((y/100. + 1.)^(1 ./4.)) .- pop
        end
    elseif var in [:obs_gdpdeflator, :obs_corepce]
        if model == :Model510
            return 100. * log.(y/100. + 1.)
        else
            return 100. * log.((y/100. + 1.)^(1 ./4.))
        end
    else
        error("untransform not implemented for $var")
    end
end

function load_conditional_data(m::AbstractModel, df::DataFrame, year::Int, quarter::Int,
                               reference_forecast::Symbol, settings::Dict{Symbol, Any};
                               cond_type::Symbol = :none, verbose::Symbol = :low)

    if cond_type in [:semi, :full]
        # Realized financial variables
        if DSGE.VERBOSITY[verbose] >= DSGE.VERBOSITY[:low]
            println("Conditioning on realized $(cond_semi_names(m))...")
        end
        cond = load_semiconditional_data(m, year, quarter, verbose = verbose)

        # If settings[:rate_expectations_source] != :none, add rate expectations
        # to cond_full_names and cond_semi_names
        if settings[:rate_expectations_source] in [:bluechip, :ois]
            ant_obs = [Symbol("obs_nominalrate$h")::Symbol for h = 1:n_anticipated_shocks(m)]
            m <= Setting(:cond_full_names, union(cond_full_names(m), ant_obs))
            m <= Setting(:cond_semi_names, union(cond_semi_names(m), ant_obs))
        end

        # Reference forecast output and inflation
        if cond_type == :full
            # Load population forecasts
            _, pop_forecast = load_realtime_population_growth(data_vintage(m), year, quarter, settings,
                                                              verbose = verbose)
            pop_growth = 100*pop_forecast[1, :filtered_population_growth]

            # Get model name
            model = realtime_unspec(m)

            if settings[:use_staff_forecasts]
                # Condition on staff forecasts of GDP and core PCE
                ref = load_system_forecast(year, quarter, reference_forecast, cond_type = :full)
                ref_longname = reference_forecast_longname(:staff)

                if size(ref, 1) == 0
                    error("$ref_longname forecast not found for $year-Q$quarter")
                else
                    if DSGE.VERBOSITY[verbose] >= DSGE.VERBOSITY[:low]
                        println("Conditioning on $ref_longname [:obs_gdp, :obs_corepce]...")
                    end

                    ind  = something(findfirst(isequal(DSGE.quartertodate(year, quarter)), ref[:date]), 0)
                    cond[:obs_gdp]     = untransform(model, :obs_gdp, ref[ind, :obs_gdp], pop_growth)
                    cond[:obs_corepce] = untransform(model, :obs_corepce, ref[ind, :obs_corepce], pop_growth)
                end
            else
                # Condition on reference forecasts of GDP and GDP deflator
                ref = load_reference_forecast(year, quarter, reference_forecast)
                ref_longname = reference_forecast_longname(reference_forecast)

                if DSGE.VERBOSITY[verbose] >= DSGE.VERBOSITY[:low]
                    println("Conditioning on $ref_longname [:obs_gdp, :obs_gdpdeflator]...")
                end

                cond[:obs_gdp]         = untransform(model, :obs_gdp, ref[1, :obs_gdp], pop_growth)
                cond[:obs_gdpdeflator] = untransform(model, :obs_gdpdeflator, ref[1, :obs_gdpdeflator], pop_growth)
            end
        end

        for col in setdiff(names(df), names(cond))
            cond[col] = NaN
        end
        df = vcat(df, cond)
        DSGE.na2nan!(df)
    end
    return df
end

function load_realtime_data(m::AbstractModel, reference_forecast::Symbol,
                            settings::Dict{Symbol, Any};
                            cond_type::Symbol = :none,
                            try_disk::Bool = true, save::Bool = true,
                            verbose::Symbol = :low)

    vint = DSGE.data_vintage(m)
    @show vint
    filestrs = OrderedDict{Symbol, Any}()
    filestrs[:spec] = m.spec
    filestrs[:hp] = settings[:hpfilter_population]
    filestrs[:vint] = vint
    addl = filestring(filestrs)

    savepath = joinpath(SMC_DIR, "save/input_data/data/realtime" * addl * ".csv")
    y, q = Dates.year(date_forecast_start(m)), Dates.quarterofyear(date_forecast_start(m))
    @show savepath
    reload_data = false
    if try_disk
        try
            # Read saved data
         #   if DSGE.VERBOSITY[verbose] >= DSGE.VERBOSITY[:low]
                println("Reading $savepath...")
         #   end
            @show savepath
            df = CSV.read(savepath)
            DSGE.format_dates!(:date, df)
            clean_df!(df)

            # Check correct
            @assert realtime_isvalid_data(m, df)
          #  if DSGE.VERBOSITY[verbose] >= DSGE.VERBOSITY[:low]
                println("Dataset from disk valid")
           # end
            reload_data = false
        catch ex
            if isa(ex, InterruptException)
                throw(ex)
            else
               # if DSGE.VERBOSITY[verbose] >= DSGE.VERBOSITY[:low]
                    @warn ex
                    println("Attempting to reload data...")
              #  end
            end
        end
    end

    if reload_data
        # Load and transform non-rate expectations data
        levels = load_realtime_levels(m, reference_forecast, y, q, verbose = verbose)
        population_growth, _ = load_realtime_population_growth(vint, y, q, settings, verbose = verbose)
        df = transform_realtime_data(m, levels, population_growth, reference_forecast, verbose = verbose)

        if save
            writetable_mkdir(savepath, df, verbose = verbose)
        end
    end

    # Load conditional data
    # This function adds an additional row to the DataFrame for the conditional
    # data period. Note that the entries in this row (or any row) for the rate
    # expectations observables will not be filled in yet.
    df = load_conditional_data(m, df, y, q, reference_forecast, settings,
                               cond_type = cond_type, verbose = verbose)

    # Load rate expectations data
    # This function fills in the rate expectations columns from
    # `date_zlb_start(m)` to the end of the DataFrame, including potentially the
    # conditional data period. It also adds the `:obs_nominalrate$i` observables
    # to `cond_semi_names(m)` and `cond_full_names(m)` so they aren't NaNed out
    # below.
    df = load_rate_expectations_data(m, df, settings, verbose = verbose)

    # NaN out conditional period variables not in `cond_semi_names(m)` or
    # `cond_full_names(m)` if necessary
    nan_cond_vars!(m, df; cond_type = cond_type)

    return df
end

"""
```
nan_cond_vars!(m, df; cond_type = :none)
```

NaN out conditional period variables not in `cond_semi_names(m)` or
`cond_full_names(m)` if necessary.
"""
function nan_cond_vars!(m::AbstractModel, df::DataFrame; cond_type::Symbol = :none)
    if cond_type in [:semi, :full]
        # Get appropriate
        cond_names = if cond_type == :semi
            cond_semi_names(m)
        elseif cond_type == :full
            cond_full_names(m)
        end

        # NaN out non-conditional variables
        cond_names_nan = setdiff(names(df), [cond_names; :date])
        T = eltype(df[:, cond_names_nan])
        df[df[:, :date] .>= date_forecast_start(m), cond_names_nan] = convert(T, NaN)

        # Warn if any conditional variables are missing
        for var in cond_names
            if any(isnan.(df[df[:, :date] .>= date_forecast_start(m), var]))
                @warn "Missing some conditional observations for " * string(var)
            end
        end
    end
end
