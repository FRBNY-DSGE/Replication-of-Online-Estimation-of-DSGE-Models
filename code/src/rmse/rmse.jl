function rmse(realized::AbstractVector{Float64}, forecasted::AbstractVector{Float64})
    @assert length(realized) == length(forecasted)
    forecast_error = forecasted - realized
    rmse(forecast_error)
end

function rmse(forecast_error::AbstractVector{Float64})
    squared_errors = forecast_error.^2
    mean_squared_error = mean(squared_errors[.!isnan.(squared_errors)])
    return sqrt(mean_squared_error)
end

function forecast_errors(var::Symbol, periods_ahead::Int,
                         forecasts::OrderedDict{Tuple{Int, Int}, DataFrame},
                         realized::DataFrame;
                         average::Bool = false, q4q4::Bool = false)

    # If realized doesn't contain variable, return NaNs
    if !(var in names(realized))
        n_forecasts = length(forecasts)
        return fill(NaN, n_forecasts)
    end

    # Initialize DataFrame
    df = DataFrame(yq = collect(keys(forecasts)), forecast = NaN, realized = NaN)

    # For each forecast vintage, get the `periods_ahead`-quarters ahead
    # forecasts for `var` and the corresponding realized value
    for (i, (y, q)) in enumerate(keys(forecasts))
        # Skip if this forecast doesn't contain variable
        if !(var in names(forecasts[(y, q)]))
            continue
        end

        if q4q4
            start_date = Dates.lastdayofyear(DSGE.quartertodate(y, q))
            date_step  = Dates.Year(1)
        else
            start_date = DSGE.quartertodate(y, q)
            date_step  = Quarter(1)
        end
        end_date = start_date + (periods_ahead - 1)*date_step

        if average
            n_horizons = periods_ahead
            dates      = start_date:date_step:end_date
        else
            n_horizons = 1
            dates      = end_date:date_step:end_date
        end
        dates = map(Dates.lastdayofquarter, dates)

        # Get forecast
        forecast_vals = fill(NaN, n_horizons)
        for j in 1:n_horizons
            forecast_ind = findfirst(forecasts[(y, q)][:date], dates[j])
            forecast_ind > 0 && (forecast_vals[j] = forecasts[(y, q)][forecast_ind, var])
        end

        # Get realized
        realized_vals = fill(NaN, n_horizons)
        for j in 1:n_horizons
            realized_ind = findfirst(realized[:date], dates[j])
            realized_ind > 0 && (realized_vals[j] = realized[realized_ind, var])
        end

        # Add means to DataFrame
        df[i, :forecast] = mean(forecast_vals)
        df[i, :realized] = mean(realized_vals)
    end

    # Calculate forecast errors
    return df[:forecast] - df[:realized]
end

"""
```
compute_rmse(base_forecasts, comp_forecasts, base_vars, comp_vars,
    reference_forecast; average = false, q4q4 = false)
```

Compute RMSEs for the base and comparison forecasts, as well as the number of
observations used at each horizon. The realized data used to compute RMSEs is
given by `plot_settings[:realized_data]`. This function is called by
`realtime_rmse` and `system_rmse`.
"""
function compute_rmse(base_forecasts::Associative{Tuple{Int, Int}, DataFrame},
                      comp_forecasts::Associative{Tuple{Int, Int}, DataFrame},
                      base_vars::Vector{Symbol}, comp_vars::Vector{Symbol},
                      reference_forecast::Symbol;
                      average::Bool = false, q4q4::Bool = false)
    # Keep only vintages with forecasts from both sources
    common_vints = intersect(keys(base_forecasts), keys(comp_forecasts))
    filter!((k, v) -> k in common_vints, base_forecasts)
    filter!((k, v) -> k in common_vints, comp_forecasts)

    # Load realized data
    realized = load_realized_data(reference_forecast)

    println("Computing RMSEs...")

    # Initialize output dictionaries
    base_rmses = Dict{Symbol, Vector{Float64}}()
    comp_rmses = Dict{Symbol, Vector{Float64}}()
    ns = Dict{Symbol, Vector{Int}}() # var -> number of observations

    # Determine number of horizons
    horizons = q4q4 ? 4 : reference_forecast_horizons(reference_forecast)

    for var in union(base_vars, comp_vars)
        # Initialize variable-specific RMSE vectors
        base_rmses[var] = fill(NaN, horizons)
        comp_rmses[var] = fill(NaN, horizons)
        ns[var]         = zeros(Int, horizons)

        # Transform realized, base, and comp back to model units
        realized[var] = if var in names(realized)
            revtrans_to_rmse_units(realized[var], var, from_4q = false, to_4q = q4q4)
        else
            NaN
        end
        if var in base_vars
            for forecast in values(base_forecasts)
                forecast[var] = revtrans_to_rmse_units(forecast[var], var, from_4q = false, to_4q = q4q4)
            end
        end
        if var in comp_vars
            for forecast in values(comp_forecasts)
                # The Q4Q4 comparison forecast must either be SEP or SPF annual. Both
                # are already in 4Q units, so they don't need to be re-cumulated
                forecast[var] = revtrans_to_rmse_units(forecast[var], var, from_4q = q4q4, to_4q = q4q4)
            end
        end

        for t in 1:horizons
            # Compute t-quarters-ahead forecast errors
            base_errors = forecast_errors(var, t, base_forecasts, realized, average = average, q4q4 = q4q4)
            comp_errors = forecast_errors(var, t, comp_forecasts, realized, average = average, q4q4 = q4q4)

            # NaN out t-quarters-ahead forecast for a certain vintage if the
            # forecast value is NaN for that vintage for any source
            @assert length(base_errors) == length(comp_errors) "Lengths of base and comp forecast errors ($(length(base_errors)) and $(length(comp_errors))) must be the same"
            for i in 1:length(base_errors)
                if isnan(base_errors[i]) || isnan(comp_errors[i])
                    base_errors[i] = NaN
                    comp_errors[i] = NaN
                end
            end

            # Compute RMSEs from forecast errors
            base_rmses[var][t] = rmse(base_errors)
            comp_rmses[var][t] = rmse(comp_errors)

            # Count number of non-NaN t-quarters-ahead forecasts that went into
            # RMSE calculation
            ns[var][t] = count(!isnan, base_errors)
        end
    end

    return base_rmses, comp_rmses, ns
end

"""
```
realtime_rmse(model, reference_forecast, input_type, cond_type, compareto;
    subspec = "", enforce_zlb = :default, average = false, q4q4 = false)
```

Compute RMSEs for the pseudo-realtime forecast given by `model`,
`reference_forecast`, `input_type`, and `cond_type` relative to the `compareto`
forecast. (Currently `compareto` can only be `:reference`.)

The keyword argument `average::Bool` specifies whether to compute RMSEs of the
average of the first h quarters instead of h-quarter-ahead forecasts.

### Outputs

- `base_rmses::Dict{Symbol, Vector{Float64}}`: maps observable names to the
  RMSEs of their 1-, 2-, ..., and 8-quarter-ahead pseudo-realtime forecasts
- `comp_rmses::Dict{Symbol, Vector{Float64}}`: same, but for the comparison
  forecast
- `ns::Dict{Symbol, Vector{Int}}`: maps observable names to numbers of non-`NaN`
  forecasts which went into each horizon's RMSE calculation
"""
function realtime_rmse(model::Symbol, reference_forecast::Symbol, input_type::Symbol, cond_type::Symbol,
                       compareto::Symbol; subspec::String = "", enforce_zlb::Symbol = :default,
                       average::Bool = false, q4q4::Bool = false)

    # Check comparison forecast is well-formed
    @assert compareto == :reference "Pseudo-realtime RMSEs must be computed relative to reference forecast"

    # Read in forecasts
    base_forecasts = read_all_realtime_forecasts(model, reference_forecast, input_type, cond_type,
                                                 subspec = subspec, enforce_zlb = enforce_zlb)
    comp_forecasts = read_all_reference_forecasts(reference_forecast)

    # Determine which variables are forecasted by each
    base_vars = realtime_vars(model)
    comp_vars = realtime_vars(reference_forecast)

    # Compute RMSEs
    compute_rmse(base_forecasts, comp_forecasts, base_vars, comp_vars, reference_forecast;
                 average = average, q4q4 = q4q4)
end

"""
```
system_rmse(cond_type, compareto, reference_forecast; average = false,
     q4q4 = false)
```

Compute RMSEs for the `cond_type` System forecast relative to the `compareto`
forecast.

The keyword argument `average::Bool` specifies whether to compute RMSEs of the
average of the first h quarters instead of h-quarter-ahead forecasts.

### Outputs

- `base_rmses::Dict{Symbol, Vector{Float64}}`: maps observable names to the
  RMSEs of their 1-, 2-, ..., and 8-quarter-ahead pseudo-realtime forecasts
- `comp_rmses::Dict{Symbol, Vector{Float64}}`: same, but for the comparison
  forecast
- `ns::Dict{Symbol, Vector{Int}}`: maps observable names to numbers of non-`NaN`
  forecasts which went into each horizon's RMSE calculation
"""
function system_rmse(cond_type::Symbol, compareto::Symbol, reference_forecast::Symbol;
                     average::Bool = false)
    # Read in forecasts
    if compareto == :sep
        comp_forecasts = read_all_sep_forecasts()
        month_of_quarter = [3, 2, 1]
        q4q4 = true
    elseif compareto == :spfq
        comp_forecasts = read_all_spf_forecasts(; annual = false)
        month_of_quarter = [2, 1]
        q4q4 = false
    elseif compareto == :reference
        comp_forecasts = read_all_reference_forecasts(reference_forecast)
        if reference_forecast == :bluechip
            month_of_quarter = if plot_settings[:allow_current_month_rmse]
                [4, 3, 2, 1]
            else
                [3, 2, 1]
            end
        else
            error("RMSEs vs. Greenbook not yet implemented")
        end
        q4q4 = false
    else
        error("Invalid compareto: $compareto")
    end
    base_forecasts = read_all_system_forecasts(reference_forecast, cond_type,
                                               forecast_only = false, month_of_quarter = month_of_quarter)

    # Determine which variables are forecasted by each
    base_vars = [:obs_gdp, :obs_corepce]
    comp_vars = if compareto in [:sep, :spfq]
        [:obs_gdp, :obs_corepce]
    elseif compareto == :reference
        realtime_vars(reference_forecast)
    end

    # Compute RMSEs
    base_rmses, comp_rmses, ns = compute_rmse(base_forecasts, comp_forecasts,
                                              base_vars, comp_vars, reference_forecast;
                                              average = average, q4q4 = q4q4)

    # MDχ: Acc. to Marco, we need to shift all of the SPF forecast comparisons to declare
    # them as two quarter ahead forecasts.
    if compareto == :spfq
        var_inds = [isassigned(base_rmses.keys, i) for i in 1:length(base_rmses.keys)]
        var_keys = base_rmses.keys[var_inds]

        for var_key in var_keys
            # Pop the NaN/0 off the end of the rmses/ns and add it to the beginning
            # so the first horizon for comparison is 2 periods ahead
            pop!(base_rmses[var_key])
            base_rmses[var_key] = vcat(NaN, base_rmses[var_key])

            pop!(comp_rmses[var_key])
            comp_rmses[var_key] = vcat(NaN, comp_rmses[var_key])

            pop!(ns[var_key])
            ns[var_key] = vcat(0, ns[var_key])
        end
    end
    return base_rmses, comp_rmses, ns
end

# Method that calls method of read_all_system_forecasts
# that manually picks the forecasts for comparison based on dates
# and assigning the first forecast quarters listed in first_fcast_qs
function system_rmse(cond_type::Symbol, compareto::Symbol,
                     reference_forecast::Symbol, dates::Vector{NTuple{2, Int}},
                     first_fcast_qs::Vector{NTuple{2, Int}};
                     average::Bool = false)
    # Read in forecasts
    if compareto == :sep
        comp_forecasts = read_all_sep_forecasts()
        q4q4 = true
    elseif compareto == :spfq
        comp_forecasts = read_all_spf_forecasts(; annual = false)
        q4q4 = false
    elseif compareto == :reference
        comp_forecasts = read_all_reference_forecasts(reference_forecast)
        q4q4 = false
    else
        error("Invalid compareto: $compareto")
    end
    base_forecasts = read_all_system_forecasts(dates, first_fcast_qs, cond_type)

    # Determine which variables are forecasted by each
    base_vars = [:obs_gdp, :obs_corepce]
    comp_vars = if compareto in [:sep, :spfq]
        [:obs_gdp, :obs_corepce]
    elseif compareto == :reference
        realtime_vars(reference_forecast)
    end

    # Compute RMSEs
    base_rmses, comp_rmses, ns = compute_rmse(base_forecasts, comp_forecasts,
                                              base_vars, comp_vars, reference_forecast;
                                              average = average, q4q4 = q4q4)

    # MDχ: Acc. to Marco, we need to shift all of the SPF forecast comparisons to declare
    # them as two quarter ahead forecasts.
    if compareto == :spfq
        var_inds = [isassigned(base_rmses.keys, i) for i in 1:length(base_rmses.keys)]
        var_keys = base_rmses.keys[var_inds]

        for var_key in var_keys
            # Pop the NaN/0 off the end of the rmses/ns and add it to the beginning
            # so the first horizon for comparison is 2 periods ahead
            pop!(base_rmses[var_key])
            base_rmses[var_key] = vcat(NaN, base_rmses[var_key])

            pop!(comp_rmses[var_key])
            comp_rmses[var_key] = vcat(NaN, comp_rmses[var_key])

            pop!(ns[var_key])
            ns[var_key] = vcat(0, ns[var_key])
        end
    end
    return base_rmses, comp_rmses, ns
end

