# File that generates all of the figures for the estimation section
# of the SMCProject paper

model = :AS #:SW

if model == :AS
    model_long = :AnSchorfheide
elseif model == :SW
    model_long = :SmetsWouters
end

# What do you want to do?
configure_master_reference  = true
construct_statistics_dfs    = false
write_adaptive_section      = true
write_time_temper_section   = true
write_multimodal_section    = true
copy_yearly_time_tempering  = true

using OrderedCollections, Distributed

# Load the SMCProject repo
@everywhere SMC_DIR = pwd()*"/../../"
@everywhere SMC_CODE_DIR = "$(SMC_DIR)/code/src/"

@everywhere include("$(SMC_CODE_DIR)/SMCProject.jl")

@everywhere using DSGE

# File paths for the paper
figures_path = "$SMC_DIR/figures_for_paper"

# Create master reference dictionary for setting and model querying
if configure_master_reference
    # Default SMCProject specs
    global est_spec  = 1
    global data_spec = 1 # No rate expectations

    settings = OrderedDict{Symbol, OrderedDict{Symbol, Any}}()

    ################################################################################
    settings[:AnSchorfheide] =
    OrderedDict(
         :model_name      => :AnSchorfheide,
         :iteration_range => 1:400,
         :run_date        => "191113", #old (what we used for original submission results): "190709",
         :est_specs => vcat(1:7, 9:24),
        :mh1_est_specs   => [1,2,5,15,16], # These est_specs correspond to 0.0, 0.98, 0.97, 0.95, 0.90, N_MH = 1 respectively
        :mh3_est_specs   => [3,6,9,11,13],
        :mh5_est_specs   => [4,7,10,12,14],
        :T_star          => quartertodate("2007-Q2"),
        :T               => quartertodate("2016-Q4"),
        :alphas          => [0.0, 0.90, 0.95, 0.97, 0.98],
        :print_strings   => OrderedDict(:est_specs => "est",
                                        :smc_iteration => "iter"),
        :tempers         => [:whole, :plus, :old, :new])

    settings[:SmetsWouters] =
    OrderedDict(
         :model_name      => :SmetsWouters,
         :iteration_range => 1:200,
         :run_date        => "191113", #"190709",
         :est_specs       => vcat(1:4, 6:16), #omit 5 because that uses 6 parameter blocks (for diffuse prior)
         :mh1_est_specs   => [1,2,6,7, 8],
         :mh3_est_specs   => [15,3,9,11,13],
         :T_star          => quartertodate("2007-Q2"),
         :T               => quartertodate("2016-Q4"),
         :alphas          => [0.0, 0.98, 0.90, 0.95, 0.97],
         :print_strings   => OrderedDict(:est_specs => "est",
                                         :smc_iteration => "iter"),
         :tempers         => [:whole, :plus, :old, :new])
    ################################################################################

    # Shorter names for convenience
    as = settings[:AnSchorfheide]
    sw = settings[:SmetsWouters]

    # Load in models to pull settings
    as[:model]      = prepare_model(as[:model_name], 2017, 1, as[:run_date], subspec = "ss0", est_spec = 1, data_spec = 1)
    sw[:model]      = prepare_model(sw[:model_name], 2017, 1, sw[:run_date], subspec = "ss1", est_spec = 1, data_spec = 1)

    as_exercise_specs = OrderedDict(:est_specs => as[:est_specs],
                                    :smc_iteration => as[:iteration_range])
    sw_exercise_specs = OrderedDict(:est_specs => sw[:est_specs],
                                    :smc_iteration => sw[:iteration_range])
end

# Load in all estimation statistics
if construct_statistics_dfs
    # A dictionary mapping model -> a dictionary mapping time tempering setting -> dataframe
    # with avg, std. log(mdd), time, schedule length etc.
    dfs      = Dict{Symbol, Dict{Symbol, DataFrame}}()

    # Load statistics for AnSchorfheide
    if model == :AS
        dfs[as[:model_name]] = load_smc_statistics_dfs(as[:model_name], as[:run_date], as[:T],
                                                       as_exercise_specs, as[:print_strings];
                                                       T_star = as[:T_star],
                                                       tempers = as[:tempers])
    elseif model == :SW

        # # Load statistics for SmetsWouters
        dfs[sw[:model_name]] = load_smc_statistics_dfs(sw[:model_name], sw[:run_date], sw[:T],
                                                       sw_exercise_specs, sw[:print_strings];
                                                       subspec = "ss1",
                                                       T_star = sw[:T_star],
                                                       tempers = sw[:tempers])
    end
    N_range_first = first(settings[model_long][:iteration_range])
    N_range_last = last(settings[model_long][:iteration_range])
    N_range_str = "$(N_range_first)_$(N_range_last)"
    jldopen("save_loaded_$(string(model))_dfs_$(N_range_str).jld2", "w") do file
        file["dfs"] = dfs
    end
end


#########################
# Section 4.1: Adaptive
#########################
if write_adaptive_section

    N_range_first = first(settings[model_long][:iteration_range])
    N_range_last = last(settings[model_long][:iteration_range])
    N_range_str = "$(N_range_first)_$(N_range_last)"
    dfs = load("save_loaded_$(string(model))_dfs_$(N_range_str).jld2", "dfs")

    colors = ["blue", "black", "green", "red", "orange"]
    if model == :AS
        # AnSchorfheide Results
        ########################
        subsection_root = "$figures_path/estimation/adaptive/as"

        # Table 1: AnSchorfheide Adaptive Schedule Statistics (from 1:T with N_MH = 1)
        write_smc_statistics_tex_table(dfs[:AnSchorfheide][:whole],
                                       drop_fixed = false,
                                       tableroot = subsection_root,
                                       filename = "table_1_as_mh1", alphas = as[:alphas],
                                       n_mhs = [1],
                                       stats = [:mean_logmdd, :std_logmdd, :mean_schedlength,
                                                :mean_resamples, :mean_min])

        write_smc_statistics_tex_table(dfs[:AnSchorfheide][:whole],
                                       drop_fixed = false,
                                       tableroot = subsection_root,
                                       filename = "table_1_as_mh3", alphas = as[:alphas],
                                       n_mhs = [3],
                                       stats = [:mean_logmdd, :std_logmdd, :mean_schedlength,
                                                :mean_resamples, :mean_min])
        write_smc_statistics_tex_table(dfs[:AnSchorfheide][:whole],
                                       drop_fixed = false,
                                       tableroot = subsection_root,
                                       filename = "table_1_as_mh5", alphas = as[:alphas],
                                       n_mhs = [5],
                                       stats = [:mean_logmdd, :std_logmdd, :mean_schedlength,
                                                :mean_resamples, :mean_min])
        gr()

        # Figure 1, Panel Left: AnSchorfheide Time v. Std log(MDD) Frontier Plot

        plot_time_std_scatter_nongadfly(sort(dfs[:AnSchorfheide][:whole], (:nmh, :alpha)),
                              file_name = "figure_1_as_mh1",
                              drop_fixed = false,
                              plotroot = subsection_root,
                              xlims = (0,5), ylims = (0,2), font_size = 14,
                              nmhs = [1],
                              colors = colors[1:1])

        plot_time_std_scatter_nongadfly(sort(dfs[:AnSchorfheide][:whole], (:nmh, :alpha)),
                              file_name = "figure_1_as_mh3",
                              drop_fixed = false,
                              plotroot = subsection_root,
                              xlims = (0,5), ylims = (0,2), font_size = 12,
                              nmhs = [3],
                              colors = colors[1:1])

        plot_time_std_scatter_nongadfly(sort(dfs[:AnSchorfheide][:whole], (:nmh, :alpha)),
                              file_name = "figure_1_as_mh12357",
                              drop_fixed = true,
                              plotroot = subsection_root,
                              xlims = (0,5), ylims = (0,2), font_size = 6,
                              nmhs = [1,2,3,5,7],
                              colors = colors[1:5])

        plot_time_std_scatter_nongadfly(sort(dfs[:AnSchorfheide][:whole], (:nmh, :alpha)),
                              file_name = "figure_1_as_mh135",
                              drop_fixed = true,
                              plotroot = subsection_root,
                              xlims = (0,6), ylims = (0,1.5), font_size = 8,
                              nmhs = [1,3,5],
                              colors = colors[1:3])

        # Figure 2, Panel Left: AnSchorfheide Tempering Schedules
        plot_tempering_schedules(as[:model], as[:run_date], as[:T],
                                 OrderedDict(:est_specs => as[:mh1_est_specs], :smc_iteration => as_exercise_specs[:smc_iteration]),
                                 as[:print_strings], est_specs_to_plot = as[:mh1_est_specs],
                                 tempers = [:whole], plotroot = subsection_root,
                                 file_name = "figure_2_tempering_scheds_as_mh1")

        plot_tempering_schedules(as[:model], as[:run_date], as[:T],
                                 OrderedDict(:est_specs => as[:mh3_est_specs], :smc_iteration => as_exercise_specs[:smc_iteration]),
                                 as[:print_strings], est_specs_to_plot = as[:mh3_est_specs],
                                 tempers = [:whole], plotroot = subsection_root,
                                 file_name = "figure_2_tempering_scheds_as_mh3")
    elseif model == :SW
        # SmetsWoutersOrig Results
        ###########################
        subsection_root = "$figures_path/estimation/adaptive/sw"

         write_smc_statistics_tex_table(dfs[:SmetsWouters][:whole],
                                        drop_fixed = false,
                                        tableroot = subsection_root,
                                        filename = "table_1_sw_mh1", alphas = as[:alphas],
                                        n_mhs = [1],
                                        stats = [:mean_logmdd, :std_logmdd, :mean_schedlength,
                                                 :mean_resamples, :mean_min])

        write_smc_statistics_tex_table(dfs[:SmetsWouters][:whole],
                                       drop_fixed = false,
                                       tableroot = subsection_root,
                                       filename = "table_1_sw_mh3", alphas = as[:alphas],
                                       n_mhs = [3],
                                       stats = [:mean_logmdd, :std_logmdd, :mean_schedlength,
                                                :mean_resamples, :mean_min])

        write_smc_statistics_tex_table(dfs[:SmetsWouters][:whole],
                                       drop_fixed = false,
                                       tableroot = subsection_root,
                                       filename = "table_1_sw_mh5", alphas = as[:alphas],
                                       n_mhs = [5],
                                       stats = [:mean_logmdd, :std_logmdd, :mean_schedlength,
                                                :mean_resamples, :mean_min])

        # Figure 1, Panel Right: SmetsWouters Time v. Std log(MDD) Frontier Plot
        # Exclude est_spec=5 because that's with 6 parameter blocks instead of 3
        plot_time_std_scatter_nongadfly(sort((dfs[:SmetsWouters][:whole])[map(x -> x != 5, dfs[:SmetsWouters][:whole][:, :est_spec]), :], (:nmh, :alpha)),
                              file_name = "figure_1_sw_mh1",
                              drop_fixed = false,
                              plotroot = subsection_root,
                              xlims = (0,200), ylims = (0,3.5),
                              font_size = 14,
                              nmhs = [1],
                              colors = colors[1:1])

        plot_time_std_scatter_nongadfly(sort((dfs[:SmetsWouters][:whole])[map(x -> x != 5, dfs[:SmetsWouters][:whole][:, :est_spec]), :], (:nmh, :alpha)),
                      file_name = "figure_1_sw_mh3",
                      drop_fixed = false,
                      plotroot = subsection_root,
                      xlims = (0,200), ylims = (0,2.5),
                      font_size = 12,
                      nmhs = [3],
                      colors = colors[1:1])

        plot_time_std_scatter_nongadfly(sort((dfs[:SmetsWouters][:whole])[map(x -> x != 5, dfs[:SmetsWouters][:whole][:, :est_spec]), :], (:nmh, :alpha)),
                              file_name = "figure_1_sw_mh135",
                              drop_fixed = true,
                              plotroot = subsection_root,
                              xlims = (0,450), ylims = (0,3.5),
                              font_size = 10,
                              nmhs = [1,3,5],
                              colors = colors[1:3])

        # Figure 2, Panel Right: SmetsWoutersOrig Tempering Schedules
        # These est_specs correspond to 0.0, 0.98, 0.97, N_MH = 1 respectively
        plot_tempering_schedules(sw[:model], sw[:run_date], sw[:T], OrderedDict(:est_specs => sw[:mh1_est_specs], :smc_iteration => sw_exercise_specs[:smc_iteration]), #sw_exercise_specs,
                                 sw[:print_strings], est_specs_to_plot = sw[:mh1_est_specs],
                                 tempers = [:whole], plotroot = subsection_root,
                                 file_name = "figure_2_tempering_scheds_sw_mh1")

        plot_tempering_schedules(sw[:model], sw[:run_date], sw[:T], OrderedDict(:est_specs => sw[:mh3_est_specs], :smc_iteration => sw_exercise_specs[:smc_iteration]), #sw_exercise_specs,
                         sw[:print_strings], est_specs_to_plot = sw[:mh3_est_specs],
                         tempers = [:whole], plotroot = subsection_root,
                         file_name = "figure_2_tempering_scheds_sw_mh3")


    end
        # (TO-DO) Appendix Figures
        # Posterior Moments Comparison (mean/quantile plots)
end

###########################
# Section 4.2: Time-Temper
###########################
if write_time_temper_section
    N_range_first = first(settings[model_long][:iteration_range])
    N_range_last = last(settings[model_long][:iteration_range])
    N_range_str = "$(N_range_first)_$(N_range_last)"
    dfs = load("save_loaded_$(string(model))_dfs_$(N_range_str).jld2", "dfs")
    # AnSchorfheide Results
    ########################
    if model == :AS
        subsection_root = "$figures_path/estimation/time_temper/as"

        # Table 2: AnSchorfheide Statistics Plus (T*+1:T)
        write_smc_statistics_tex_table(dfs[:AnSchorfheide][:plus],
                                       drop_fixed = true, tableroot = subsection_root,
                                       filename = "table_2_as_mh1", alphas = setdiff(as[:alphas], [0.0]),
                                       n_mhs = [1],
                                       stats = [:mean_logmdd, :std_logmdd,
                                                :mean_schedlength, :mean_min])

        write_smc_statistics_tex_table(dfs[:AnSchorfheide][:plus],
                                       drop_fixed = true, tableroot = subsection_root,
                                       filename = "table_2_as_mh3", alphas = setdiff(as[:alphas], [0.0]),
                                       n_mhs = [3],
                                       stats = [:mean_logmdd, :std_logmdd,
                                                :mean_schedlength, :mean_min])

        write_smc_statistics_tex_table(dfs[:AnSchorfheide][:plus],
                                       drop_fixed = true, tableroot = subsection_root,
                                       filename = "table_2_as_mh5", alphas = setdiff(as[:alphas], [0.0]),
                                       n_mhs = [5],
                                       stats = [:mean_logmdd, :std_logmdd,
                                                :mean_schedlength, :mean_min])


        # Figure 3: AnSchorfheide Time v. Std log(MDD) Frontier Plot, Whole (1:T) vs Plus (T*+1:T)
        plot_time_std_scatter_nongadfly(dfs[:AnSchorfheide],
                              drop_fixed = true, file_name = "figure_3_as_mh1",
                              tempers = [:whole, :plus],
                              plotroot = subsection_root,
                              xlims = (0,3.5),
                              ylims = (0, 1.5),
                              font_size = 12)

        plot_time_std_scatter_nongadfly(dfs[:AnSchorfheide],
                              drop_fixed = true, file_name = "figure_3_as_mh3",
                              tempers = [:whole, :plus],
                              plotroot = subsection_root,
                              xlims = (0,4),
                              ylims = (0,2),
                              font_size = 12,
                              n_mh = 3)
    elseif model == :SW
        # SmetsWoutersOrig Results
        ########################
        subsection_root = "$figures_path/estimation/time_temper/sw"

        write_smc_statistics_tex_table(dfs[:SmetsWouters][:plus],
                                       drop_fixed = true, tableroot = subsection_root,
                                       filename = "table_2_sw_mh1", alphas = setdiff(as[:alphas], [0.0]),
                                       n_mhs = [1],
                                       stats = [:mean_logmdd, :std_logmdd,
                                                :mean_schedlength, :mean_min])

        write_smc_statistics_tex_table(dfs[:SmetsWouters][:plus],
                               drop_fixed = true, tableroot = subsection_root,
                               filename = "table_2_sw_mh3", alphas = setdiff(as[:alphas], [0.0]),
                               n_mhs = [3],
                               stats = [:mean_logmdd, :std_logmdd,
                                        :mean_schedlength, :mean_min])

         write_smc_statistics_tex_table(dfs[:SmetsWouters][:plus],
                               drop_fixed = true, tableroot = subsection_root,
                               filename = "table_2_sw_mh5", alphas = setdiff(as[:alphas], [0.0]),
                               n_mhs = [5],
                               stats = [:mean_logmdd, :std_logmdd,
                                        :mean_schedlength, :mean_min])

        # Figure 3, Right Panel: SmetsWoutersOrig Time v. Std log(MDD) Frontier Plot,
        # Whole (1:T) vs Plus (T*+1:T)
        plot_time_std_scatter_nongadfly(dfs[:SmetsWouters],
                              drop_fixed = true, file_name = "figure_3_sw_mh1",
                              tempers = [:whole, :plus],
                              plotroot = subsection_root,
                              xlims = (0,200), ylims = (0, 3.5),
                              font_size = 12,
                              n_mh = 1)

        plot_time_std_scatter_nongadfly(dfs[:SmetsWouters],
                        drop_fixed = true, file_name = "figure_3_sw_mh3",
                        tempers = [:whole, :plus],
                        plotroot = subsection_root,
                        xlims = (0,200), ylims = (0,1.5),
                        font_size = 12,
                        n_mh = 3)
    end
end

#####################################
# Section 4.3: Multimodal Posteriors
#####################################
if write_multimodal_section
    sw_model = SmetsWouters()
    m904_model = Model904()

    # Standard Prior
    est_spec = 2
    # vint = "190213"
    vint = "190629" #"190717" #"190629"
    # SW
    cloud = load("$SMC_DIR/save/$(vint)/output_data/smets_wouters/ss1/estimate/raw/smc_cloud_est=$(est_spec)_vint=920110.jld2", "cloud") #load("$SMC_DIR/save/190709/output_data/smets_wouters/ss1/estimate/raw/smc_cloud_est=$(est_spec)_iter=1_vint=070710.jld2", "cloud")
    savepath = "$figures_path/estimation/standard_vs_diffuse/sw/ss1"
    plot_multimode_nongadfly(sw_model, cloud, :ι_p, :ρ_λ_f, savepath, "920110",
                   color_scale_limits = (0, 9), xlims = (-0.1, 1.2), ylims = (-0.1, 1.2))
    plot_multimode_nongadfly(sw_model, cloud, :ι_p, :η_gz, savepath, "920110",
                   color_scale_limits = (0, 4.5), xlims = (-0.1, 1.2), ylims = (-0.1, 1.2))
    plot_multimode_nongadfly(sw_model, cloud, :S′′, :ρ_λ_f, savepath, "920110")
    plot_multimode_nongadfly(sw_model, cloud, :h, :ρ_λ_f, savepath, "920110",
                   color_scale_limits = (0, 14), xlims = (0.1, 1.0), ylims = (-0.1, 1.2))

   #= # 904
    cloud = load("$SMC_DIR/save/$(vint)/output_data/m904/ss10/estimate/raw/smc_cloud_est=$(est_spec)_prev=920110_vint=930110.jld2", "cloud")
    savepath = "$figures_path/estimation/standard_vs_diffuse/m904/ss10"
    plot_multimode(m904_model, cloud, :α, :h, savepath, "930110")
    plot_multimode(m904_model, cloud, :h, :σ_c, savepath, "930110")
    plot_multimode(m904_model, cloud, :h, :σ_b, savepath, "930110")
    plot_multimode(m904_model, cloud, :σ_c, :σ_b, savepath, "930110")
=#
    # Diffuse Prior
    est_spec = 5
    vint = "190227" #"190717" #"190227"

    # SW
    cloud = load("$SMC_DIR/save/$(vint)/output_data/smets_wouters/ss6/estimate/raw/smc_cloud_est=$(est_spec)_vint=920110.jld2", "cloud")
    savepath = "$figures_path/estimation/standard_vs_diffuse/sw/ss6"
    plot_multimode_nongadfly(sw_model, cloud, :ι_p, :ρ_λ_f, savepath, "920110",
                   color_scale_limits = (0, 9), xlims = (-0.1, 1.2), ylims = (-0.1, 1.2))
    plot_multimode_nongadfly(sw_model, cloud, :ι_p, :η_gz, savepath, "920110",
                   color_scale_limits = (0, 4.5), xlims = (-0.1, 1.2), ylims = (-0.1, 1.2))
    plot_multimode_nongadfly(sw_model, cloud, :S′′, :ρ_λ_f, savepath, "920110")
    plot_multimode_nongadfly(sw_model, cloud, :h, :ρ_λ_f, savepath, "920110",
                   color_scale_limits = (0, 14), xlims = (0.1, 1.0), ylims = (-0.1, 1.2))

 #=   # 904
    cloud = load("$SMC_DIR/save/$(vint)/output_data/m904/ss13/estimate/raw/smc_cloud_est=$(est_spec)_prev=920110_vint=930110.jld2", "cloud")
    savepath = "$figures_path/estimation/standard_vs_diffuse/m904/ss13"
    plot_multimode(m904_model, cloud, :α, :h, savepath, "930110")
    plot_multimode(m904_model, cloud, :h, :σ_c, savepath, "930110")
    plot_multimode(m904_model, cloud, :h, :σ_b, savepath, "930110")
    plot_multimode(m904_model, cloud, :σ_c, :σ_b, savepath, "930110") =#
end

# (TO-DO) Put this in the appendix
###################################################
# Appendix: Number of Metropolis Hastings Steps
###################################################


# TEST io.jl functionality
if false
    m = deepcopy(as[:model])
    # exercise_specifications = OrderedDict(:est_specs        => 1:5,
                                          # :smc_iteration    => 1:20)
    exercise_specifications = OrderedDict(:est_specs => vcat(1:7, 9:16),
                                          :smc_iteration    => 1:50)
    print_strings = OrderedDict(:est_specs      => "est",
                                :smc_iteration  => "iter")
    outputs   = [:clouds, :mdds, :alphas, :n_mhs]
    # outputs   = [:clouds, :mdds, :alphas]
    label_key = :temper_type

    # Dates
    T_star = quartertodate("2007-Q2")
    T      = quartertodate("2017-Q1")

    # Load things
    m <= Setting(:data_vintage, forecast_vintage(T_star))
    db_old = load_clouds(m, exercise_specifications, print_strings,
                         outputs = outputs, label_key = label_key, label_value = :old)
    m <= Setting(:data_vintage, forecast_vintage(T))
    db_whole = load_clouds(m, exercise_specifications, print_strings,
                           outputs = outputs, label_key = label_key, label_value = :whole)
    m <= Setting(:previous_data_vintage, forecast_vintage(T_star), true, "prev", "")
    m <= Setting(:data_vintage, forecast_vintage(T))
    db_new = load_clouds(m, exercise_specifications, print_strings,
                         outputs = outputs, label_key = label_key, label_value = :new)
    # test some stuff
    db_old[!,:runtime]      = map(x -> x.total_sampling_time/60, db_old[:clouds])
    db_old[!,:sched_length] = map(x -> x.stage_index, db_old[:clouds])

    db_whole[!,:runtime]      = map(x -> x.total_sampling_time/60, db_whole[:clouds])
    db_whole[!,:sched_length] = map(x -> x.stage_index, db_whole[:clouds])

    db_new[!,:runtime]      = map(x -> x.total_sampling_time/60, db_new[:clouds])
    db_new[!,:sched_length] = map(x -> x.stage_index, db_new[:clouds])

    db_plus = deepcopy(db_new)
    db_plus[!,:mdds] = db_old[:mdds] + db_new[:mdds]

    # Temper method
    db_temper = load_clouds(m, T, exercise_specifications,
                            print_strings,
                            outputs = outputs, tempers = [:new, :old, :plus, :whole],
                            T_star = T_star)

    # Try some querying
    begin
        temp = @from i in db_temper begin
               @where i.est_specs == 2
               @select {i.mdds, i.temper_type, i.sched_length}
               @collect DataFrame
        end
    end

    begin
        temp = @from i in db_temper begin
                   # group by est_spec, and two temper types (:old, :new)
                   @group i by {i.est_specs, i.temper_type} into g
                   # @select {key = key(g),
                   @select {key = key(g),
                            mdds = mean(g.mdds)}
                   @collect DataFrame
               end
    end

    # Load that stats df!
    dfs = load_smc_statistics_dfs(as[:model_name], as[:run_date], T,
                                  exercise_specifications, print_strings,
                                  T_star = T_star, tempers = [:old, :new, :whole, :plus])
end

if copy_yearly_time_tempering
    # Grab plots from from where the specAnSchorfheideExercise.jl saved them
    cp("$(SMC_DIR)/save/200123/output_data/an_schorfheide/ss0/estimate/figures/", "$(SMC_DIR)/figures_for_paper/estimation/time_temper/as/an_schorfheide_exercise", force = true)
end
