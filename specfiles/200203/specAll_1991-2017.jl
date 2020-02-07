using DSGE
using DSGEModels
using ClusterManagers, Distributed
addprocs(collect(eachline("nodefile")); tunnel = true, topology = :master_worker)
@everywhere using DSGE, DSGEModels

@everywhere SMC_DIR = ### INSERT PATH TO WHEREVER YOU GIT CLONED REPO
@everywhere SMC_CODE_DIR = "$(SMC_DIR)/code/src"
@everywhere include("$(SMC_CODE_DIR)/SMCProject.jl")
@everywhere using Distributions, DataFrames
@everywhere import DSGE: quartertodate

# What dated directory does this specfile live in?
run_date = "200203"

# Model Settings
if ARGS[1] == "m805"
    model = :Model805
elseif ARGS[1] == "m904"
    model = :Model904
elseif ARGS[1] == "sw"
    model = :SmetsWouters
end
ss    = ARGS[2]

T0      = quartertodate("1991-Q4")
T       = quartertodate("2017-Q4")
Ts      = quarter_range(T0, T)
Ts      = Base.filter(x -> Dates.month(x) == 12, Ts) # To get an annual range
if (model == :Model805 && ss == "ss1" ) || (model == :Model904 && ss == "ss10") ||
    (model == :SmetsWouters && ss == "ss1")
    est_spec  = 2 # a = 0.98, n_mh = 1
elseif (model == :Model805 && ss == "ss4" ) || (model == :Model904 && ss == "ss13") ||
    (model == :SmetsWouters && ss == "ss6")
    est_spec  = 5 # a = 0.98, n_mh = 1, n_blocks = 6
end
data_spec = 1 # No rate expectations

# Estimate 1993-Q1 from scratch then time temper in the rest
# Missing hours and wages data up until 1964-Q2 so cannot use chand_recursion
setting_overrides = Dict{Symbol, Setting}(:use_chand_recursion => Setting(:use_chand_recursion, false))

println("########################")
println("Beginning estimation $T0")
println("########################")

# # Estimating old
estimate_model(model, Dates.year(T0), Dates.quarterofyear(T0), run_date, subspec = ss,
               est_spec = est_spec, data_spec = data_spec, setting_overrides = setting_overrides)

Ts_current  = Ts[2:end]
Ts_previous = Ts[1:end-1]

#    t  t-1
for (t, t_1) in zip(Ts_current, Ts_previous)
    println("##############################################")
    println("Beginning estimation of $t, tempered from $t_1")
    println("##############################################")

    # Setting overrides keeps getting carried over across estimations..
    # may need to put this inside the loop.. but that doesn't seem like a great solution.
    setting_overrides = Dict{Symbol, Setting}(:use_chand_recursion => Setting(:use_chand_recursion, false))
    if t_1 != T0
        # Setting the previous_data_vintage for the t_1 (old) estimation
        # so it should be the data vintage of t-2, which is a year before t-1
        # Note when the t period model is being setup in the estimate_model driver
        # it overwrites the setting_override[:previous_data_vintage] to be the vintage of the t_1 model.
        setting_overrides[:previous_data_vintage] = Setting(:previous_data_vintage, forecast_vintage(iterate_quarters(t_1, -4)),
                                                            true, "prev", "Print the previous data vintage")
    end

    # Estimating new
    estimate_model(model, t_1, t, run_date, subspec = ss, est_spec = est_spec, data_spec = data_spec,
                   setting_overrides = setting_overrides)
end

rmprocs(procs())
