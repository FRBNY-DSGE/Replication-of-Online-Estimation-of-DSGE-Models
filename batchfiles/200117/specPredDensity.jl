using DSGE
using DSGEModels
using ClusterManagers, Distributed

pr_arg = ARGS[2]
cond_arg = ARGS[3]
m_arg = ARGS[4]
p_np = ARGS[5]

if p_np == "point"
    point_forecast = true
elseif p_np == "nonpoint"
    point_forecast = false
end

addprocs(collect(eachline("nodefile")); tunnel = true, topology = :all_to_all)
@everywhere using DSGE, DSGEModels

# What do you want to do?
run_smc = true

@everywhere SMC_DIR = "/scratch/exm190011/SMCProject_submission"
@everywhere SMC_CODE_DIR = "$(SMC_DIR)/code/src/"
@everywhere include("$(SMC_CODE_DIR)/SMCProject.jl")
@everywhere using Distributions, DataFrames
@everywhere import DSGE: quartertodate

# Common setup
input_type = :full
# input_type = :mode
parallel = input_type == :full ? true : false

#data_spec = 4 # Bluechip rate expectations
est_spec  = 2
#cond_type = :full
start_date = quartertodate("1991-Q4")
end_date   = quartertodate("2016-Q4")

use_final_realized_as_observed = true

######
# SMC
######
if cond_arg=="bluechip"
    dspec = (4, :semi)
elseif cond_arg=="neither"
    dspec = (1, :semi)
elseif cond_arg=="nowcast"
    dspec = (1, :full)
elseif cond_arg=="nowcast_bluechip"
    dspec = (4, :full)
end

if run_smc
    # For nowcast & bluechip, nowcast, bluechip, and neither
    # for (data_spec, cond_type) in [(4, :full), (1, :full), (4, :semi), (1, :semi)]
    for (data_spec, cond_type) in [dspec]
        estimation_date = "190629"
        save_date       = "200117"

        if pr_arg == "diffuse"
            est_spec        = 5 # α = 0.98, n_mh = 1, n_smc_blocks = 6 (use for diffuse prior)
            subspecs = ("ss6", "ss4", "ss13")
        elseif pr_arg == "standard"
            est_spec        = 2 # α = 0.98, n_mh = 1
            subspecs = ("ss1", "ss1", "ss10")
        end
        # For standard and diffuse
        for predicted_variables in [[:obs_gdp], [:obs_gdpdeflator], [:obs_gdp, :obs_gdpdeflator]]
            if predicted_variables == [:obs_gdp]
                pred_var_string = "gdp"
            elseif predicted_variables == [:obs_gdpdeflator]
                pred_var_string = "def"
            else
                pred_var_string = "both"
            end
            println("For $pred_var_string...")

            # for subs in [("ss1", "ss1", "ss10"), ("ss6", "ss4", "ss13")]
            #  for subs in [("ss1", "ss1", "ss10")]
            for subs in [subspecs]
                if subs == ("ss1", "ss1", "ss10")
                    println("Calculating predictive densities for standard prior...")
                else
                    println("Calculating predictive densities for diffuse prior...")
                end

                sw_ss, m805_ss, m904_ss = subs
                for horizon in [2, 4, 6, 8]
                    println("On horizon $horizon.")

                    if m_arg=="sw"
                        println("Starting Smets Wouters")
                        model = :SmetsWouters
                        logscores_sw = calculate_predictive_density_model(model, start_date, end_date,
                        input_type, cond_type, horizon,
                        predicted_variables, estimation_date, :SMC;
                        point_forecast = point_forecast,
                        save_date = save_date, subspec = sw_ss,
                        data_spec = data_spec, est_spec = est_spec,
                        use_final_realized_as_observed =
                            use_final_realized_as_observed,
                        save_aux_dir =
                            "pred_densities_$pred_var_string",
                        parallel = parallel,
                        verbose = :none)
                    elseif m_arg == "swff"
                        println("Starting M904")
                        model = :Model904
                        logscores_swff = calculate_predictive_density_model(model, start_date, end_date,
                        input_type, cond_type, horizon,
                        predicted_variables, estimation_date, :SMC;
                        point_forecast = point_forecast,
                        save_date = save_date, subspec = m904_ss,
                        data_spec = data_spec, est_spec = est_spec,
                        use_final_realized_as_observed =
                            use_final_realized_as_observed,
                        save_aux_dir = "pred_densities_$pred_var_string",
                        parallel = parallel, verbose = :none)
                    elseif m_arg == "swpi"
                        println("Starting M805")
                        model = :Model805
                        logscores_swff = calculate_predictive_density_model(model, start_date, end_date,
                        input_type, cond_type, horizon,
                        predicted_variables, estimation_date, :SMC;
                        point_forecast = point_forecast,
                        save_date = save_date, subspec = m805_ss,
                        data_spec = data_spec, est_spec = est_spec,
                        use_final_realized_as_observed =
                            use_final_realized_as_observed,
                        save_aux_dir = "pred_densities_$pred_var_string",
                        parallel = parallel, verbose = :none)
                    end
                end
            end
        end
    end
end

# rmprocs(procs())
