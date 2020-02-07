using DSGEModels, StateSpaceRoutines
import DSGE: quartertodate, datetoquarter, iterate_quarters

EST_SPEC = 1 # No rate expectations
FCAST_SPEC = 1
include("$(SMC_DIR)/code/src/RealtimeData/src/RealtimeData.jl")

year = 1992
quarter = 1
input_type = :mode
parallel = input_type == :full ? true : false

horizon = 1
start_date = quartertodate("1992-Q1")
cond_types = [:none, :semi]

#######################################################
cond_type = :none
model = :Model805
subspec = "ss1"
end_date = DSGE.iterate_quarters(start_date, 1)
run_date = "190107"
data_spec = 1 # no interest rate expectations
est_spec  = 2
m = Model805()
predicted_variables = collect(keys(m.observables))

# Calculate the predictive density of y^o_t given data up until t-1, where the observables contained in y are all of the
# observables in the model. I.e p(y^o_t|y_{1:t-1})
# In this test case, we are calculating the predictive density for a single period t, where t = 1992-Q1.
# When using no conditional data, the full suite of observables (as given by predicted_variables),
# and a horizon = 1 (that is, not calculating the predictive density of an average over multiple horizons \bar{y}^o_t)
# Then we can check the correctness of the predictive density code against the predictive density
# that would arise from the Kalman filter over the same period.
# To be explicit: logscores_sw[1] = p(y^o_t|y_{1:t-1}, θ)
logscores_sw = calculate_predictive_density_model(model, start_date, end_date, input_type,
                                                  cond_type, horizon, predicted_variables, run_date, :MH;
                                                  subspec = subspec, data_spec = data_spec, est_spec = est_spec)

########################################
# Comparing to Kalman Filter Output
########################################
# First we are instantiating the model and loading the data in the same way that was done in the predictive
# density codebase so that the Kalman filter is run with the same set of system matrices and data
# as in the predictive density codebase.
length_log = subtract_quarters(quartertodate("$year-Q$quarter"), start_date) + 1
m = prepare_model(model, year, quarter, run_date; subspec = subspec)
params, data, data_o = setup_params_and_data(m, input_type, length_log, horizon, start_date)
DSGE.update!(m, params)
system   = compute_system(m)
measrmnt = measurement(m, system[:TTT], system[:RRR], system[:CCC])

# Note: loglh is 128 entries long because it is the set of predictive densities
# calculated from t0 = 1960-Q1 through t-1 = 1991-Q4. This can be checked by subtracting the two
# quarters from one another.

# No entry in loglh can be directly compared to logscores_sw[1] since the latest predictive
# density it contains is the one for the t-1 period, that is, p(y_{t-1}|y_{1:t-2}).
# Further, it cannot be compared directly because that observed data period, y_{t-1}, comes from the `data`
# dataset and not `data_o`, which because the data gets revised has a different y^o_{t-1} than `data`.
# However, what we can do instead is take the last period of the s_filt, and P_filt from the Kalman filter,
# that is, s_{t-1}|{t-1} and P_{t-1}|{t-1}, and use them to construct the y_t and V_t used to
# parameterize the MvNormal distribution. Once we have that MvNormal distribution, we can evaluate the y^o_t data point given by `data_o` at that distribution to get the t-th period predictive density implied by the Kalman filter.
loglh, s_pred, P_pred, s_filt, P_filt, s0, P0, s_T, P_T = kalman_filter(data, system[:TTT], system[:RRR],
                                                                        system[:CCC], measrmnt[:QQ],
                                                                        measrmnt[:ZZ], measrmnt[:DD],
                                                                        measrmnt[:EE], Nt0 = n_presample_periods(m))

s_t_t1_kal = system[:TTT] * s_filt[:, end]
P_t_t1_kal = system[:TTT] * P_filt[:, :, end] * system[:TTT]' + system[:RRR] * system[:QQ] * system[:RRR]'
y_t_t1_kal = system[:DD] + system[:ZZ] * s_t_t1_kal
V_t_t1_kal = system[:ZZ] * P_t_t1_kal * system[:ZZ]'
V_t_t1_kal = (V_t_t1_kal + V_t_t1_kal')/2
dist_kal   = MultivariateNormal(y_t_t1_kal, V_t_t1_kal)
p_y_o_kal  = logpdf(dist_kal, data_o[:, end])

# This checks that the predictive density code matches the Kalman filter implied predictive density for the t-th period.
@test logscores_sw[1] ≈ p_y_o_kal
