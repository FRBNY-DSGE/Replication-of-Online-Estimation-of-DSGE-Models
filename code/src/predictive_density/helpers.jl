function setup_params_and_data(m::AbstractModel, input_type::Symbol, i::Int64,
                               horizon::Int64, start_date::Date = quartertodate("1960-Q1");
                               data_spec::Int64 = 0,
                               estimation_override::String = "",
                               use_final_realized_as_observed::Bool = true)

    # start_date is the first forecast quarter. Since we are incrementing i
    # for each forecast quarter in the sample
    # and since i starts at 1 we need to adjust the index by -1.
    increment_model_vint!(m, i-1, start_date)
    df   = load_realtime_data(m; verbose = :none)
    data = df_to_matrix(m, df)

    # Constructing the input_file override to load in the parameters for MH
    # SMC functionality now moved higher level to drivers.jl where estimation_overrides
    # are constructed to avoid annoying vintage relabeling (juggling prev and curr vints) at this level.
    if isempty(estimation_override)
        if get_setting(m, :sampling_method) == :MH
            # Setting the model vintage to correspond to the vintage of the most recent estimation
            # (Estimations were run annually)
            # `ninetythree_override` since we have SMC estimations that precede the first estimated MH vintage 930110.
            annualize_model_vint!(m, df, mh_estimation = true)

            input_file = input_type == :full ? rawpath(m, "estimate", "mhsave.h5") : rawpath(m, "estimate", "paramsmode.h5")

            # est=1 corresponds to estimations run without rate expectations
            # est=4 corresponds to estimations run with rate expectations during the recession
            # To economize on time during the realtime project because an est=1 and est=4 estimation
            # are equivalent prior to the ZLB, we only ran `true` est=1 estimations (i.e. files named as such) after the ZLB period.
            # Because we want to calculate predictive densities w/o rate expectations for all years,
            # we must selectively load est=4 estimations pre-ZLB, and est=1 estimations post.
            pre_zlb_vints = ["920110", "930110", "940110", "950110", "960110", "970110", "980110",
                             "990110", "000110", "010110", "020110", "030110", "040110", "050110",
                             "060110", "070110", "080110"]

            # The criteria for using estimations that had rate expectations
            # This is complicated and terrible, so it should be re-factored,
            # but this is essentially what the conditional means
            # Case 1: If the vintage is pre-ZLB and the model was estimated with a standard prior
            # then because pre-ZLB, with (est=4) and without (est=1) rate expectations estimations are the same,
            # and because we have standard prior estimations for est=4, we want to use them.
            # Case 2: If the vintage is in the ZLB, and the model was estimated with a standard prior,
            # and the data_spec is either 2 (OIS) or 4 (Bluechip), then we want to use estimations that
            # incorporated rate expectations.
            case1a = data_vintage(m) in pre_zlb_vints
            case1b = !get_setting(m, :using_diffuse_prior)
            case1  = case1a && case1b
            case2a = !(data_vintage(m) in pre_zlb_vints)
            case2b = !get_setting(m, :using_diffuse_prior)
            case2c = data_spec in [2,4]
            case2 = case2a && case2b && case2c
            if case1 || case2
                input_file = replace(input_file, "est=1" => "est=4")
            end

            # Issue is that the same vintaged override keeps being reused because we're replacing
            # est=4 with est=1, but the override vintage stays at whatever the first "realtime_forecast_input_file!"
            # gave it. E.g. if we set start_date = 1992-Q1, then the vintage of parameters that is
            # used remains at 1993 indefinitely.
            # Solution: Enforce input_file to bypass get_forecast_input_file (and thus ignoring
            # previous overrides), to load from the rawpath and hence be aligned to the
            # model's actual vintage.
            realtime_forecast_input_file!(m, input_type, input_file)
        else
            error("Invalid :sampling_method model setting/input_type combination")
        end
    end

    params =
        if isempty(estimation_override)
            load_draws(m, input_type; verbose = :none)
        else
            if get_setting(m, :sampling_method) == :MH
                map(Float64, h5read(estimation_override, "mhparams"))
            else
                map(Float64, h5read(estimation_override, "smcparams"))
            end
        end

    if get_setting(m, :sampling_method) == :MH && input_type == :full
        params = thin_mh_draws(m, params)

        # The diffuse prior smets wouters estimations
        # did incorporate the measurement error parameters,
        # so no need to hcat on zeros
        if spec(m) == "smets_wouters" && subspec(m) == "ss1"
            # Because measurement error terms for each of the observables in
            # the SmetsWouters model were added after the realtime estimations were completed
            # the number of parameters need to be adjusted. Thankfully, all m.e. terms
            # were fixed to be 0, so we just need to cat on a matrix of 0's.
            # BUT, we need to correct by subtracting n_anticipated shocks since apparently we don't have measurement error parameters for these guys (nominal_rate1-6)
            params = hcat(params, zeros(size(params, 1), n_observables(m) - n_anticipated_shocks(m)))
        end
    end

    # Construct the realized data series to use for conditional data
    # (taking a period off data_o to tack onto data as the conditional period) and for predictive density evaluation.
    increment_model_vint!(m, horizon+i-1, start_date)
    if use_final_realized_as_observed
        df_o_raw = CSV.read("$(SMC_DIR)/save/input_data/data/realtime/input_data/data/revisedfinal_vint=190418.csv")

        # Add rate expectations to the revised final dataset
        if n_anticipated_shocks(m) > 0
            # OIS
            if data_spec == 2
                ois_file = get_setting(m, :rate_expectations_post_liftoff) ? "ois_170615.csv" : "ois.csv"
                df_o_raw_aug = CSV.read(joinpath(SMC_DIR, "save/input_data/data", ois_file))
                names!(df_o_raw_aug, [:date, :obs_nominalrate1, :obs_nominalrate2, :obs_nominalrate3, :obs_nominalrate4, :obs_nominalrate5, :obs_nominalrate6])
                df_o_raw = join(df_o_raw, df_o_raw_aug, on = :date, kind = :left)
            # Bluechip
            elseif data_spec == 4
                # Initialize columns with NaNs
                for h = 1:6
                    df_o_raw[Symbol("obs_nominalrate$h")] = fill(NaN, size(df_o_raw, 1))
                end

                # Because 2016-Q4 is the last date we have bluechip forecasts.
                # Doesn't matter since ZLB ends after 2015-Q1 anyway.
                for date in DSGE.quarter_range(date_zlb_start(m), quartertodate("2016-Q4"))
                    # Load Blue Chip forecast
                    y, q = Dates.year(date), Dates.quarterofyear(date)
                    ref  = load_reference_forecast(y, q, :bluechip)

                    # Find corresponding quarter in df_o_raw
                    df_o_raw_date_ind = findfirst(x -> x == date, df_o_raw[:date] )

                    for h = 1:6
                        # Suppose (y, q) = (2009, 4). Then load_reference_forecast loads
                        # the January 2010 Blue Chip forecast, whose first forecasted
                        # quarter (first row) is 2009-Q4. The observations we want to
                        # put in df_o_raw[:obs_nominalrate$h] are those from 2010-Q1 (second
                        # row) on, so we use ref[h+1, :obs_nominalrate]

                        # If necessary, divide by 4 to go from annualized to quarterly
                        # rate expectations
                        df_o_raw[df_o_raw_date_ind, Symbol("obs_nominalrate$h")] = ref[h+1, :obs_nominalrate] / 4
                    end
                end
            else
                throw("Invalid data_spec for having n_anticipated_shocks(m) > 0. Must be either 2 (ois rate expectations) or 4 (bluechip rate expectations)")
            end
        end

        # Subset to time T since we're using the revised final dataset for all predictive density forecasts
        T_ind = findfirst(x -> x == DSGE.iterate_quarters(date_forecast_start(m), -1), df_o_raw[:date])
        df_o  = df_o_raw[1:T_ind, :]
        data_o = df_to_matrix(m, df_o)
    else # Loads the first data released (unrevised) as the observed data
        df_o = load_realtime_data(m; verbose = :none)
        data_o = df_to_matrix(m, df_o)
    end

    return params, data, data_o
end

function construct_semi_cond_data(m::AbstractModel, data_o::Matrix{Float64}, t1_ind::Int64)
    all_cond_vars = [:obs_nominalrate, :obs_spread]

    if n_anticipated_shocks(m) > 0
        ant_shock_vars = Vector{Symbol}(undef, n_anticipated_shocks(m))
        for h = 1:n_anticipated_shocks(m)
            ant_shock_vars[h] = Symbol("obs_nominalrate$h")
        end
        all_cond_vars = vcat(all_cond_vars, ant_shock_vars)
    end

    cond_vars = intersect(m.observables.keys, all_cond_vars)
    inds = Vector{Int64}(undef, length(cond_vars))
    for (i, var) in enumerate(cond_vars)
        inds[i] = m.observables[var]
    end
    semi_cond_data = fill(NaN, size(data_o, 1), 1)
    semi_cond_data[inds] = data_o[inds, t1_ind+1]
    return semi_cond_data
end

function construct_full_cond_data(m::AbstractModel, data_o::Matrix{Float64}, t1_ind::Int64)
    all_cond_vars = [:obs_gdp, :obs_gdpdeflator, :obs_nominalrate, :obs_spread]

    if n_anticipated_shocks(m) > 0
        ant_shock_vars = Vector{Symbol}(undef, n_anticipated_shocks(m))
        for h = 1:n_anticipated_shocks(m)
            ant_shock_vars[h] = Symbol("obs_nominalrate$h")
        end
        all_cond_vars = vcat(all_cond_vars, ant_shock_vars)
    end

    cond_vars = intersect(m.observables.keys, all_cond_vars)
    inds = Vector{Int64}(undef, length(cond_vars))
    for (i, var) in enumerate(cond_vars)
        inds[i] = m.observables[var]
    end
    semi_cond_data = fill(NaN, size(data_o, 1), 1)
    semi_cond_data[inds] = data_o[inds, t1_ind+1]
    return semi_cond_data
end


function forecast_states(s::Vector{S}, P::Matrix{S}, system::System{S},
                         horizon::Int64; all_out::Bool = false,
                         s_all::Vector{Vector{S}} = Vector{Vector{S}}(undef, horizon),
                         P_all::Vector{Matrix{S}} = Vector{Matrix{S}}(undef, horizon),
                         s_t_t1::Vector{S} = Vector{S}(undef, 0),
                         P_t_t1::Matrix{S} = Matrix{S}(undef, 0, 0)) where S<:AbstractFloat
    @assert horizon > 0

    cond = !isempty(s_t_t1) && !isempty(P_t_t1)

    TTT = system[:TTT]
    RRR = system[:RRR]
    QQ = system[:QQ]

    # Forecast
    if cond
        s_new = s_t_t1
        P_new = P_t_t1
    else
        s_new = TTT*s
        P_new = TTT*P*TTT' + RRR*QQ*RRR'
    end

    s_all[horizon] = s_new
    P_all[horizon] = P_new

    horizon = horizon - 1

    if horizon == 0
        if all_out
            return reverse(s_all), reverse(P_all)
        else
            return s_new, P_new
        end
    else
        forecast_states(s_new, P_new, system, horizon, all_out = all_out, s_all = s_all, P_all = P_all)
    end
end

function construct_shat_Phat(s_all::Vector{Vector{S}},
                             P_all::Vector{Matrix{S}},
                             system::System{S}) where S<:AbstractFloat
    TTT = system[:TTT]

    horizon  = length(s_all)-1
    num_states = length(s_all[1])

    s_hat = zeros(num_states * (horizon+1))
    P_hat = zeros((horizon+1)*num_states, (horizon+1)*num_states)

    # Is there a cleaner way to do this?
    for (k, s, P) in zip(1:horizon+1, s_all, P_all)
        subsec_inds = ((k-1)*num_states+1):(k*num_states)
        s_hat[subsec_inds] = s_all[k]

        # Fill the corner
        P_hat[subsec_inds, subsec_inds] = P_all[k]

        for (i, j) in zip(k:horizon, 1:length(k:horizon))
            # Fill down the rows and columns
            block_inds = (i*num_states+1):((i+1)*num_states)

            P_hat[block_inds, subsec_inds] = TTT^j*P
            P_hat[subsec_inds, block_inds] = P*(TTT^j)'
        end
    end
    return s_hat, P_hat
end

# Constructing the F matrix to compute forecasts either averaged
# across a horizon, or a point forecast.
"""
```
function construct_F(n_obs, horizon; annualized = true, average = true)
```

Construct the F matrix (as notated by the Dynamic Prediction Pool's computational
appendix) for computing linear combinations of y^o_{t:t+h}. Given a horizon, h,
one can use F to compute an h-period forward-looking average from y^o_{t:t+h} (setting
`point_forecast = false`), or to take the point forecast for the h-period ahead entry of y^o_{t:t+h}
(setting `point_forecast = true`).
"""
function construct_F(n_obs::Int64, horizon::Int64;
                     annualized::Bool = true, point_forecast::Bool = false)
    # Choose the values to populate the non-zero'd out diagonals
    # of F. This is based on whether we want to annualize (multiply everything
    # by 4) and whether we want to average (dividing by the horizon).
    if annualized
        if point_forecast
            diag_entries = fill(4., n_obs)
        else
            diag_entries = fill(4 ./horizon, n_obs)
        end
    else
        if point_forecast
            diag_entries = fill(1. , n_obs)
        else
            diag_entries = fill(1 ./horizon, n_obs)
        end
    end

    # Find the diagonal offset indices to populate the entries
    ind_tuple  = construct_index_tuple(n_obs, horizon)
    if point_forecast
        # For point forecasts of `horizon` you want to populate the diagonal
        # corresponding to `horizon` with non-zero values, and the rest with zero values,
        # thus returning F y^o_{t:t+h} = y^o_{t+h}
        set_entry(ind) = ind == ((horizon - 1)*n_obs) ? diag_entries : fill(0., n_obs)
        pairs = map(x -> Pair(x, set_entry(x)), ind_tuple)
    else
        # For averages over `horizon` you want to populate all of the diagonals with
        # 4./horizon, thus returning F y^o_{t:t+h} = \bar{y}^o_{t:t+h}
        pairs = map(x -> Pair(x, diag_entries), ind_tuple)
    end
    F = sparse(SparseArrays.spdiagm_internal(pairs...)...)

    return F
end

function construct_y_o_and_measurement_eq(data_o::Matrix{Float64},
                                          system::System, horizon::Int64,
                                          ant_shock_inds::Vector{Int64},
                                          non_ant_shock_inds::Vector{Int64};
                                          point_forecast::Bool = false)

    t_ind = size(data_o, 2) - horizon + 1  # the first forecast period

    # If the model has anticipated shocks, check if the realized values in the first
    # forecast period contains NaN values in the indices corresponding to the anticipated shocks
    if !isempty(ant_shock_inds) && isnan(data_o[:, t_ind][ant_shock_inds][1])
        n_obs = length(non_ant_shock_inds)

        # Subsetting out of the periods that don't have anticipated shocks
        data_o_subset = data_o[non_ant_shock_inds, :]

        y_o = vec(data_o_subset[:, t_ind:(t_ind + horizon - 1)])

        D_tilde = kron(ones(horizon), system[:DD][non_ant_shock_inds])
        Z_tilde = kron(Matrix(1.0I, horizon, horizon), system[:ZZ][non_ant_shock_inds, :])
    else
        n_obs = size(data_o, 1)

        y_o = vec(data_o[:, t_ind:(t_ind + horizon - 1)])

        D_tilde = kron(ones(horizon), system[:DD])
        Z_tilde = kron(Matrix(1.0I, horizon, horizon), system[:ZZ])
    end
    F = construct_F(n_obs, horizon; point_forecast = point_forecast)

    return F, y_o, D_tilde, Z_tilde
end
