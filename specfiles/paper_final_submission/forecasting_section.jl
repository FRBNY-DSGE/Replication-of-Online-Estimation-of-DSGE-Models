# File that generates all of the figures for the forecasting section
# of the SMCProject paper, as well as any other forecasting results
# that ended up in the appendix. This includes predictive densities and RMSEs.

# What do you want to do?
configure_master_reference                             = true
generate_predictive_densities_with_standard_prior      = true
generate_predictive_density_comparisons_across_priors  = true
generate_predictive_densities_across_time              = true

using Distributed
using OrderedCollections
using Plots, Measures
gr()

@everywhere SMC_DIR = pwd()*"/../../"
@everywhere SMC_CODE_DIR = "$(SMC_DIR)/code/src/"
@everywhere include("$SMC_CODE_DIR/SMCProject.jl")

@everywhere using DSGE

# File paths for the paper
figures_path = "$SMC_DIR/figures_for_paper"

if configure_master_reference
    settings = OrderedDict{Symbol, Any}()

    settings[:model_names]       = [:SmetsWouters, :Model805, :Model904]
    settings[:model_specs]       = ["smets_wouters", "m805", "m904"]
    settings[:model_strings]     = ["sw", "swpi", "swff"]
    settings[:model_colors]      = [:blue, :purple, :red]
    settings[:standard_subspecs] = ["ss1", "ss1", "ss10"]
    settings[:diffuse_subspecs]  = ["ss6", "ss4", "ss13"]
    settings[:model_comparisons] = [(:SmetsWouters, :Model904), (:Model805, :Model904)]
    settings[:model_comparison_subfolders] = Dict{Tuple{Symbol, Symbol}, String}((:SmetsWouters, :Model904) => "SWvm904",
                                                                                 (:Model805, :Model904) => "m805vm904")
    settings[:horizons]    = [2, 4, 6, 8]
                           # (4) With rate expectations, (1) without rate expectations
    settings[:data_specs]  = [4, 1]
    settings[:predicted_variables] = [[:obs_gdp], [:obs_gdpdeflator], [:obs_gdp, :obs_gdpdeflator]]
    settings[:cond_types]  = [:full, :semi]
    settings[:standard_est_spec] = 2 # α = 0.98, n_mh = 1
    settings[:diffuse_est_spec]  = 5 # α = 0.98, n_mh = 1, n_smc_blocks = 6 (use for diffuse prior, m904 ss13)
    settings[:sampling_method] = :SMC
    settings[:start_date] = quartertodate("1991-Q4")
    settings[:end_date]   = quartertodate("2016-Q4")
    settings[:date_sample_names] = [:post_recession, :whole_sample]
    settings[:date_samples] = [(quartertodate("2011-Q1"), quartertodate("2016-Q1")),
                               (quartertodate("1991-Q4"), quartertodate("2016-Q4"))]
    # Average
    settings[:standard_load_date] = "200202" #"191218" #"190704" #"190620"
    settings[:diffuse_load_date]  = "200202" #"191218" #"190704" #"190620"
    # Point
    settings[:standard_point_load_date] = "200202" #"191218" #"190704" #"190619"
    settings[:diffuse_point_load_date]  = "200202" #"191218" #"190704" #"190619"
    # Where the Average MH Predictive Densities are saved
    settings[:mh_load_date] = "190621"

    # (2) Into the paper's figures directory
    settings[:standard_plotroot]  = "$(figures_path)/forecasting/predictive_densities/standard_prior"
    settings[:diffuse_plotroot]   = "$(figures_path)/forecasting/predictive_densities/prior_comparison"
    settings[:estimation_comparison_plotroot] = "$(figures_path)/forecasting/predictive_densities/estimation_comparison"
    settings[:rmse_plotroot]      = "$(figures_path)/forecasting/rmses/smc/standard_prior"
end

# Constructing the y-axes
ylims_timeavg = OrderedDict{String, Tuple}()
ylims_timeavg["gdp"] = (-2.9, -1.5)
# ylims_timeavg["def"] = (-2.0, -0.5)
ylims_timeavg["def"] = (-3.0, -0.5)
# ylims_timeavg["both"] = (-4.4, -2.3)
ylims_timeavg["both"] = (-6.0, -2.3)

# For indexing into entries in `settings` that are model-ordered
get_index(model_name) = findfirst(x -> x == model_name, settings[:model_names])

if generate_predictive_densities_with_standard_prior
    # Plot Average Predictive Densities for SW v. SWFF and SWpi vs SWFF
    # for the Post-Recession and Whole Sample
    for (date_sample, date_range) in zip(settings[:date_sample_names], settings[:date_samples])
        sample_start_date, sample_end_date = date_range
        for predicted_variables in settings[:predicted_variables]
            pred_var_string = predicted_variables_to_filestring(predicted_variables)
            save_aux_dir    = "pred_densities_$pred_var_string"
            for (data_spec, cond_type) in product(settings[:data_specs], settings[:cond_types])
                for (base_model, comp_model) in settings[:model_comparisons]
                    for point_forecast in [false] #[true, false]
                        load_date = point_forecast ? settings[:standard_point_load_date] : settings[:standard_load_date]
                        model_comparison_subfolder = settings[:model_comparison_subfolders][(base_model, comp_model)]

                        plot_time_averaged_predictive_density_comparison(base_model, comp_model,
                                          settings[:standard_subspecs][get_index(base_model)],
                                          settings[:standard_subspecs][get_index(comp_model)],
                                          cond_type, predicted_variables,
                                          settings[:horizons],
                                          settings[:start_date], settings[:end_date],
                                          load_date, settings[:sampling_method],
                                          data_spec, settings[:standard_est_spec],
                                          settings[:standard_est_spec];
                                          point_forecast = point_forecast,
                                          plot_start_date = sample_start_date,
                                          plot_end_date   = sample_end_date,
                                          ylims = ylims_timeavg[pred_var_string],
                                          base_color = settings[:model_colors][get_index(base_model)],
                                          comp_color = settings[:model_colors][get_index(comp_model)],
                                          base_model_string = settings[:model_strings][get_index(base_model)],
                                          comp_model_string = settings[:model_strings][get_index(comp_model)],
                                          plotroot = settings[:standard_plotroot],
                                          save_aux_dir = save_aux_dir,
                                          save_aux_subdir = model_comparison_subfolder)
                    end
                end
            end
        end
    end
end

if generate_predictive_density_comparisons_across_priors
    # Plot Diffuse Prior Comparisons for the Post-Recession and Whole Sample
    for (date_sample, date_range) in zip(settings[:date_sample_names], settings[:date_samples])
        sample_start_date, sample_end_date = date_range
        for predicted_variables in settings[:predicted_variables]
            pred_var_string = predicted_variables_to_filestring(predicted_variables)
            save_aux_dir    = "pred_densities_$pred_var_string"
            for (data_spec, cond_type) in product(settings[:data_specs], settings[:cond_types])
                for model in settings[:model_names]
                    plot_time_averaged_predictive_density_comparison(model, model,
                                      settings[:standard_subspecs][get_index(model)],
                                      settings[:diffuse_subspecs][get_index(model)],
                                      cond_type, predicted_variables,
                                      settings[:horizons],
                                      settings[:start_date], settings[:end_date],
                                      settings[:diffuse_load_date],
                                      settings[:sampling_method],
                                      data_spec, settings[:standard_est_spec],
                                      settings[:diffuse_est_spec],
                                      plot_start_date = sample_start_date;
                                      plot_end_date   = sample_end_date,
                                      ylims = ylims_timeavg[pred_var_string],
                                      base_linestyle = :solid,
                                      comp_linestyle = :dash,
                                      base_color = settings[:model_colors][get_index(model)],
                                      comp_color = settings[:model_colors][get_index(model)],
                                      base_model_string = settings[:model_strings][get_index(model)],
                                      comp_model_string = settings[:model_strings][get_index(model)],
                                      plotroot = settings[:diffuse_plotroot],
                                      save_aux_dir = save_aux_dir,
                                      save_aux_subdir = settings[:model_specs][get_index(model)])
                end
            end
        end
    end
end

if generate_predictive_densities_across_time
    # Plot Predictive Densities across time for SW v. SWFF and SWpi vs SWFF
    # for the Post-Recession and Whole Sample
    for (date_sample, date_range) in zip(settings[:date_sample_names], settings[:date_samples])
        sample_start_date, sample_end_date = date_range

        ylims_across_time = OrderedDict{String, Tuple{Float64, Float64}}()
        ylims_across_time["gdp"]  = (-9.0, -1.0)
        ylims_across_time["def"]  = (-4.0, 0.0)
        ylims_across_time["both"] = (-11.0, -1.0)
        for predicted_variables in settings[:predicted_variables]
            pred_var_string = predicted_variables_to_filestring(predicted_variables)
            save_aux_dir    = "pred_densities_$pred_var_string"
            for (data_spec, cond_type) in product(settings[:data_specs], settings[:cond_types])
                filestring_ext  = data_spec_and_cond_type_to_filestring(data_spec, cond_type)
                for (base_model, comp_model) in settings[:model_comparisons]
                    for point_forecast in [false]#[true, false]
                        load_date = point_forecast ? settings[:standard_point_load_date] : settings[:standard_load_date]
                        model_comparison_subfolder = settings[:model_comparison_subfolders][(base_model, comp_model)]
                        for horizon in settings[:horizons]
                            plot_predictive_density_over_time_comparison(base_model, comp_model,
                                                                         settings[:standard_subspecs][get_index(base_model)],
                                                                         settings[:standard_subspecs][get_index(comp_model)],
                                                                         settings[:start_date], settings[:end_date],
                                                                         :full, cond_type, horizon, data_spec, load_date,
                                                                         settings[:standard_est_spec],
                                                                         settings[:standard_est_spec],
                                                                         point_forecast = point_forecast,
                                                                         plot_start_date = sample_start_date,
                                                                         plot_end_date   = sample_end_date,
                                                                         colors_set = settings[:model_colors][[get_index(base_model),
                                                                                                               get_index(comp_model)]],
                                                                         ylims = ylims_across_time[pred_var_string],
                                                                         plotroot = settings[:standard_plotroot],
                                                                         save_aux_dir = save_aux_dir,
                                                                         save_aux_subdir = model_comparison_subfolder,
                                                                         filestring_ext = filestring_ext)
                        end
                    end
                end
            end
        end
    end
end
