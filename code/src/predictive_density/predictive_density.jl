import DSGE: quartertodate, iterate_quarters, subtract_quarters

# 1. Consider t-1 to be the "current" period, so the forecast of t|t-1 corresponds to horizon = 1
# 2. start_date is the first forecast quarter
# The convention that is followed in the realtime code base is that year/quarter refer to
# the first forecast quarter.
function compute_predictive_densities(m::AbstractModel, input_type::Symbol,
                                      start_date::Date, end_date::Date, horizon::Int64,
                                      predicted_variables::Vector{Symbol};
                                      cond_type::Symbol = :none,
                                      est_spec::Int = 0, fcast_spec::Int = 0,
                                      data_spec::Int = 0, parallel::Bool = false,
                                      estimation_overrides::Vector{String} = Vector{String}(undef, 0),
                                      use_final_realized_as_observed::Bool = true,
                                      point_forecast::Bool = false)
    # Forecast horizon
    @assert horizon > 0

    indices = Vector{Int}(undef, subtract_quarters(end_date, start_date) + 1)

    output = @distributed (vcat) for i in 1:length(indices)
        if get_setting(m, :sampling_method) == :SMC
            estimation_override = estimation_overrides[i]
        else
            estimation_override = ""
        end

        # Step 1: Draw load-in and model solve
        params, data, data_o = setup_params_and_data(m, input_type, i, horizon, start_date,
                                                     data_spec = data_spec,
                                                     use_final_realized_as_observed =
                                                     use_final_realized_as_observed,
                                                     estimation_override = estimation_override)

        if input_type == :mode
            p_y_o = compute_predictive_density(m, params, horizon, data, data_o,
                                               predicted_variables; cond_type = cond_type,
                                               point_forecast = point_forecast)
        elseif input_type == :full
            n_draws = size(params, 1)
            p_y_o = [compute_predictive_density(m, params[j, :], horizon, data, data_o,
                                                predicted_variables, cond_type = cond_type,
                                                point_forecast = point_forecast)
                     for j in 1:n_draws]
        else
            throw("Invalid input_type. Must be :mode or :full")
        end

        p_y_o, i
    end

    # N_draws x N_vintages
    logscores_unordered = Matrix{Float64}(undef, length(output[1][1]), length(indices))

    for i in 1:length(indices)
        logscores_unordered[:, i] = output[i][1]
        indices[i]                = output[i][2]
    end
    logscores = logscores_unordered[:, indices]

    return logscores
end

function compute_predictive_density(m::AbstractModel, params::Vector{Float64},
                                    horizon::Int64, data::Matrix{Float64},
                                    data_o::Matrix{Float64},
                                    predicted_variables::Vector{Symbol};
                                    cond_type::Symbol = :none,
                                    point_forecast::Bool = false)
    n_obs = size(data, 1)
    ant_shock_inds = find_ant_shock_inds(m)
    non_ant_shock_inds = setdiff(1:n_obs, ant_shock_inds)

    DSGE.update!(m, params)
    system = compute_system(m)

    # Step 2 and 3: Run the Kalman filter and forecast
    if cond_type == :none
        kal     = DSGE.filter(m, data, system)
        s_t1_t1 = kal[:s_filt][:, end]
        P_t1_t1 = kal[:P_filt][:, :, end]

        s_t_t1 = Vector{Float64}(undef, 0)
        P_t_t1 = Matrix{Float64}(undef, 0, 0)
    elseif cond_type == :semi
        t1_ind = size(data, 2)
        semi_cond_data = construct_semi_cond_data(m, data_o, t1_ind)
        data_aug = hcat(data, semi_cond_data)

        kal = DSGE.filter(m, data_aug, system)
        s_t1_t1 = kal[:s_filt][:, end-1]
        P_t1_t1 = kal[:P_filt][:, :, end-1]

        s_t_t1 = kal[:s_filt][:, end]
        P_t_t1 = kal[:P_filt][:, :, end]
    elseif cond_type == :full
        t1_ind = size(data, 2)
        full_cond_data = construct_full_cond_data(m, data_o, t1_ind)
        data_aug = hcat(data, full_cond_data)

        kal = DSGE.filter(m, data_aug, system)
        s_t1_t1 = kal[:s_filt][:, end-1]
        P_t1_t1 = kal[:P_filt][:, :, end-1]

        s_t_t1 = kal[:s_filt][:, end]
        P_t_t1 = kal[:P_filt][:, :, end]
    end

    # Step 4: Recursive construction of s_ and P_hat_t+j|t-1
    s_all, P_all = forecast_states(s_t1_t1, P_t1_t1, system, horizon, all_out = true,
                                   s_t_t1 = s_t_t1, P_t_t1 = P_t_t1)

    s_hat, P_hat = construct_shat_Phat(s_all, P_all, system)

    # Step 5 & 6
    F, y_o, D_tilde, Z_tilde = construct_y_o_and_measurement_eq(data_o, system, horizon,
                                                                ant_shock_inds,
                                                                non_ant_shock_inds;
                                                                point_forecast = point_forecast)

    # In the conditional case the eigenvalues for ZPZ for the rows corresponding to the
    # two conditional variables (obs_nominalrate and obs_spread) are 0 (on the order of 1e-16)
    # but because we are taking a 4q average this is fine. If you try to do just 1 period
    # ahead predictive density then it breaks because V is then not PSD

    μ = F * D_tilde + F * Z_tilde * s_hat
    V = F * Z_tilde * P_hat * Z_tilde' * F'

    V = Matrix((V + V') / 2)

    inds = predicted_variable_inds(m, predicted_variables)

    dist  = MultivariateNormal(μ[inds], V[inds, inds])
    p_y_o = logpdf(dist, (F*y_o)[inds])

    return p_y_o
end
