using DSGE
using Distributed
numprocs = parse(Int, ARGS[1])
numnodes = ceil(Int, numprocs/16)

#addprocs(SlurmManager(numprocs), nodes=numnodes, topology = :master_worker)
addprocs(collect(eachline("nodefile")); tunnel=true, topology=:master_worker)
@everywhere using DSGE

@everywhere SMC_CODE_DIR = "$(SMC_DIR)/code/src/"
@everywhere include("$(SMC_CODE_DIR)/SMCProject.jl")

@everywhere using Distributions, DataFrames
@everywhere import DSGE: quartertodate

# What do you want to do?
run_estimations = true

# What dated directory does this specfile live in?
run_date = "200202"

# Model Settings
model = :SmetsWouters
# corresponds to old ending in 2007-Q1
T       = quartertodate("2007-Q2")
# corresponds to new ending in 2016-Q3
T_star  = quartertodate("2016-Q4")
# the est_spec is the second argument
global est_spec = parse(Int, ARGS[2])
data_spec = 1 # No rate expectations

##########################################################
# AS dataset override used to run Sections 2 and 3 results
df = load("$(SMC_DIR)/save/input_data/sw_data.jld2", "df")
df_T      = subset_df(df, T, forecast_date = true)
df_T_star = subset_df(df, T_star, forecast_date = true)
##########################################################

if run_estimations
    #i is the iteration number--it's the third argument
    i = parse(Int, ARGS[3])
    # setting_overrides keeps getting carried over across estimation..
    # may need to put this inside the loop.. but that doesn't seem like a great solution.
    setting_overrides = Dict{Symbol, Setting}(:use_chand_recursion =>
                                              Setting(:use_chand_recursion, true),
                                              :date_presample_start =>
                                              Setting(:date_presample_start, quartertodate("1965-Q4")),
                                              :date_mainsample_start =>
                                              Setting(:date_mainsample_start, quartertodate("1966-Q4")))

    println("Beginning iteration $i whole")
    # Estimating whole
    estimate_model(model, T_star, run_date, subspec = "ss0", est_spec = est_spec, data_spec = data_spec,
                       data_override = df_T_star, setting_overrides = setting_overrides, iteration = i)

        println("Beginning iteration $i old")
        # Estimating old
        estimate_model(model, T, run_date, subspec = "ss0",  est_spec = est_spec, data_spec = data_spec,
                       data_override = df_T, setting_overrides = setting_overrides, iteration = i)

        println("Beginning iteration $i new")
        # Estimating new
        estimate_model(model, T, T_star, run_date, subspec = "ss0", est_spec = est_spec, data_spec = data_spec,
                       data_override_T = df_T, data_override_T_star = df_T_star,
                       setting_overrides = setting_overrides, iteration = i)
    end

    #  rmprocs(procs())
end
