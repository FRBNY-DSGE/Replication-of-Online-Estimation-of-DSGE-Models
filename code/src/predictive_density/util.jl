function find_ant_shock_inds(m::AbstractModel)
    n_ant_shocks = n_anticipated_shocks(m)
    shock_inds = Vector{Int64}(undef, n_ant_shocks)

    for i in 1:n_ant_shocks
        shock_inds[i] = m.observables[Symbol("obs_nominalrate", i)]
    end
    return shock_inds
end

# Allows for a custom thinning factor (jstep) to be specified
# If not, it pulls the jstep from the model
function thin_mh_draws(m::AbstractModel, params::Matrix{Float64}; jstep::Int64 = 1)
    jstep = jstep == 1 ? m.settings[:forecast_jstep].value : jstep
    n_total_draws, n_params = size(params)
    # Thin as usual if n_total_draws % jstep == 0
    # If it does not evenly divide, then start from the remainder+1-th index
    # and then take a thinned subset from there
    n_new_draws, offset = divrem(n_total_draws, jstep)
    params_thinned = Matrix{Float64}(undef, n_new_draws, n_params)
    params_offset = params[offset+1:end, :]

    for (i, j) in enumerate(1:jstep:n_total_draws)
        params_thinned[i, :] = params_offset[j, :]
    end
    return params_thinned
end

function construct_diag_tuple(diag_entries::Vector{Float64}, horizon::Int64)
    diag_array = [diag_entries for i in 1:horizon]
    return (diag_array...,)
end

function construct_index_tuple(n_obs::Int64, horizon::Int64)
    indices = Vector{Int64}(undef, horizon)
    for i in 1:horizon
        indices[i] = (i-1)*n_obs
    end
    return (indices...,)
end

# date should be the first forecast quarter
# e.g. the vintage 920410 corresponds to having data up to 1991-Q4
function date_to_realtime_vint(date::Date)
    yr = Dates.year(date)
    day = "10"
    if Dates.month(date) == 3
        mo = "04"
    elseif Dates.month(date) == 6
        mo = "07"
    elseif Dates.month(date) == 9
        mo = "10"
    elseif Dates.month(date) == 12
        mo = "01"
        yr = yr + 1
    end
    yr = string(yr)[3:4]
    return yr*mo*day
end

# Convenience function for updating the model settings
# for calculating the predictive densities for an SMC estimation
function annualize_realtime_vint(vint::String; previous_year::Bool = false)
    if previous_year
        # Handle the edge case of 2000
        curr_year = Meta.parse(vint[1:2])
        prev_year = curr_year == 0 ? 99 : curr_year - 1

        return lpad(string(prev_year), 2, "0")*"0110"
    else
        return vint[1:2]*"0110"
    end
end

function increment_model_vint!(m::AbstractModel, incr::Int64,
                               start_date::Date)
    date = iterate_quarters(start_date, incr)
    vint = date_to_realtime_vint(date)

    m <= Setting(:data_vintage, vint)
    m <= Setting(:date_forecast_start, date)
    m <= Setting(:date_conditional_end, date)
end

# To determine which parameters to load for a given vintage one
# must separately update the vintage (for loading parameters) since
# the parameters are only estimated annually (using each year's data
# up to Q4).
function annualize_model_vint!(m::AbstractModel, df::DataFrame;
                               mh_estimation::Bool = true)
    last_data_period = df[end, :date]
    if Dates.quarterofyear(last_data_period) in [3, 4]
        vint_year = Dates.year(last_data_period) + 1
    else
        vint_year = Dates.year(last_data_period)
    end

    # Because mh estimations only go up to the 160110 vintage
    if mh_estimation
        y = vint_year > 2016 ? 2016 : vint_year
    else
        y = vint_year
    end

    y = string(y)[3:4]
    m <= Setting(:data_vintage, y*"0110")
end

function predicted_variable_inds(m::AbstractModel, predicted_variables::Vector{Symbol})
    n_pred_vars = length(predicted_variables)
    inds = Vector{Int64}(undef, n_pred_vars)
    for (i, var) in enumerate(predicted_variables)
        inds[i] = m.observables[var]
    end
    return inds
end
