function load_first_finals(reference_forecast::Symbol)
    filename = joinpath(SMC_DIR, "input_data", "data", "$(reference_forecast)_ffinal.csv")
    println("Reading $(reference_forecast_longname(reference_forecast)) vintage first finals...")
    df = CSV.read(filename)

    if reference_forecast == :bluechip
        # Keep only observations corresponding to correct
        # BLUECHIP_FORECAST_MONTH
        keep_indices = [(month(Date(x, "yyyy-mm-dd")) % 3 == BLUECHIP_FORECAST_MONTH % 3)::Bool for x in df[:date]]
        df = df[keep_indices, :]

        DSGE.format_dates!(:date, df)

        # If BLUECHIP_FORECAST_MONTH == 1, assign the observation to the
        # previous quarter
        if BLUECHIP_FORECAST_MONTH == 1
            df[:date] = map(x -> DSGE.iterate_quarters(x, -1), df[:date])
        end

    elseif reference_forecast == :greenbook
        error("We haven't figured out how to programmatically determine Greenbook vintages yet...")
    else
        error("Invalid reference forecast $reference_forecast")
    end

    # Rename headers from bluechip_xxx or greenbook_xxx to obs_xxx
    for var in realtime_vars(reference_forecast)
        ref_var = Symbol(replace(string(var), "obs", string(reference_forecast)))
        rename!(df, ref_var => var)
    end

    return clean_df!(df)
end

function load_revised_finals(; try_disk::Bool = true, save::Bool = true)

    vint = plot_settings[:current_vintage]
    savepath = joinpath(SMC_DIR, "input_data", "data", "revisedfinal_vint=$vint.csv")

    reload_data = true
    if try_disk
        try
            # Read saved data
            println("Reading $savepath...")
            transformed = CSV.read(savepath)
            DSGE.format_dates!(:date, transformed)
            clean_df!(transformed)
            reload_data = false
        catch ex
            isa(ex, InterruptException) && throw(ex)
            warn(ex)
            println("Attempting to reload data...")
        end
    end

    if reload_data
        # Dates
        vint_date  = vintage_to_date(plot_settings[:current_vintage])
        start_date = DSGE.iterate_quarters(DSGE.quartertodate(plot_settings[:realtime_start]...), -1)
        end_date   = DSGE.iterate_quarters(vint_date, -1)

        # Load levels from FRED
        vintaged_series = [:GDP, :GDPDEF, :JCXFE]
        unvintaged_series = [:DFF]
        levels = load_fred_data(vintaged_series, unvintaged_series, start_date, end_date, vint_date)

        # Reverse transform: into annualized Q/Q percent change (GDP, GDP deflator)
        # or percent (FFR)
        transformed = DataFrame(date = levels[:date])
        transformed[:obs_gdp]         = loggrowthtopct_annualized(oneqtrpctchange(levels[:GDP] ./ levels[:GDPDEF]))
        transformed[:obs_gdpdeflator] = loggrowthtopct_annualized(oneqtrpctchange(levels[:GDPDEF]))
        transformed[:obs_corepce]     = loggrowthtopct_annualized(oneqtrpctchange(levels[:JCXFE]))
        transformed[:obs_nominalrate] = levels[:DFF]

        if save
            writetable_mkdir(savepath, transformed)
        end
    end

    return transformed
end

"""
```
load_realized_data(reference_forecast)
```

Load the *reverse transformed* realized data for the `reference_forecast`
sample. This function depends on the value of `plot_settings[:realized_data]`,
which can be either `:firstfinal` (the third and final release for each quarter,
before any revisions) or `:revisedfinal` (the most recent vintages, which may
include revisions. The exact vintage is set as
`plot_settings[:current_vintage]`).
"""
function load_realized_data(reference_forecast::Symbol,
                            try_disk::Bool = true, save::Bool = true)

    if PLOT_SPEC == 1
        # Replicate Handbook
        return load_handbook_finals(reference_forecast)
    else
        if plot_settings[:realized_data] == :firstfinal
            return load_first_finals(reference_forecast)
        elseif plot_settings[:realized_data] == :revisedfinal
            return load_revised_finals(try_disk = try_disk, save = save)
        else
            error("Invalid value for plot_settings[:realized_data]: $(plot_settings[:realized_data])")
        end
    end
end