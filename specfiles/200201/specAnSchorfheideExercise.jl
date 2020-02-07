# This specfile was written to run an incremental AS estimation exercise
# suggested by Frank Schorfheide
# The exercise is as follows:
# Partition the sample into 1:T_1, T_1 + 1:T_2, ... and add observations in
# blocks of 4 (annual).
# Recursively estimate using SMC tempering in each of these increments
# and record the average runtime and standard deviation of the log MDD
# for the whole tempered component (p(y_1:T_s) = p(y_{T_s-1+1:T_s}|y_{1:T_{s-1})p(y_{1:T_{s-1})
# and just the "new" tempered component, p(y_{T_s-1+1:T_s}|y_{1:T_{s-1})

# Note: I am loading data "unvintaged", i.e. NOT realtime data. just
# subsets from T.

# Set worker memory
ENV["frbnyjuliamemory"] = "3G"
# Add workers
addprocs_frbny(48)

@everywhere SMC_DIR = ### INSERT PATH TO WHEREVER YOU GIT CLONED REPO
@everywhere SMC_CODE_DIR = "$(SMC_DIR)/code/src/"

@everywhere include("$(SMC_CODE_DIR)/SMCProject.jl")

@everywhere using DSGE

using OrderedCollections
import DSGE: quartertodate, quarter_range, iterate_quarters

# What dated directory does this specfile live in?
run_date = "200201"

# What do you want to do?
load_in_data    = true
run_estimations = true
configure_master_reference = true
plot_figures    = true

# Model Settings
model   = :AnSchorfheide
ss      = "ss0"
T0      = quartertodate("1991-Q4")
T       = quartertodate("2016-Q4")
Ts      = quarter_range(T0, T)
Ts      = Base.filter(x -> Dates.month(x) == 12, Ts) # To get an annual range
est_spec  = 2 # a = 0.98, n_mh = 1          #15 # a = 0.95, n_mh = 1
data_spec = 1 # No rate expectations

# Generate by subsets as opposed to using real real-time
# so we can use chandrasekhar recursions
if load_in_data
    df = load("$(SMC_DIR)/save/input_data/as_data.jld2", "df")
end

if run_estimations
    N_sim   = 200

    run_from_scratch = false
    run_tempered     = true

    # Run "from-scratch" estimations
    if run_from_scratch
        for i in 1:N_sim
            setting_overrides = Dict{Symbol, Setting}(:use_chand_recursion =>
                                                      Setting(:use_chand_recursion, true),
                                                      :date_presample_start =>
                                                      Setting(:date_presample_start, quartertodate("1965-Q4")),
                                                      :date_mainsample_start =>
                                                      Setting(:date_mainsample_start, quartertodate("1966-Q4")))


            # So you're not re-estimating the initial old estimation
            # up to T0 that is used in the tempered section
            for t in Ts[2:end]
                # Construct the data set with data up to Q3 (first_forecast_quarter - 1)
                # for T0 using "unvintaged" data from T
                df_t = df[1:findfirst(x -> x == iterate_quarters(t, -1), df[:date]), :]

                println("########################")
                println("Beginning estimation $t")
                println("########################")

                estimate_model(model, t, run_date, subspec = ss, est_spec = est_spec, data_spec = data_spec,
                               iteration = i, setting_overrides = setting_overrides, verbose = :none,
                               data_override = df_t)
            end
        end
    end

    # Run tempered estimations
    if run_tempered
        for i in 1:N_sim
            setting_overrides = Dict{Symbol, Setting}(:use_chand_recursion =>
                                                      Setting(:use_chand_recursion, true),
                                                      :date_presample_start =>
                                                      Setting(:date_presample_start, quartertodate("1965-Q4")),
                                                      :date_mainsample_start =>
                                                      Setting(:date_mainsample_start, quartertodate("1966-Q4")))

            # Construct the data set with data up to Q3 (first_forecast_quarter - 1)
            # for T0 using "unvintaged" data from T
            df_T0 = df[1:findfirst(x -> x == iterate_quarters(T0, -1), df[:date]), :]

            println("########################")
            println("Beginning estimation $T0")
            println("########################")
            # # Estimating old
            estimate_model(model, T0, run_date, subspec = ss, est_spec = est_spec, data_spec = data_spec,
                           iteration = i, setting_overrides = setting_overrides, verbose = :none,
                           data_override = df_T0)

            Ts_current  = Ts[2:end]
            Ts_previous = Ts[1:end-1]

            #    t  t-1
            for (t, t_1) in zip(Ts_current, Ts_previous)
                println("##############################################")
                println("Beginning estimation of $t, tempered from $t_1")
                println("##############################################")

                # Construct the data set with data up to Q3 (first_forecast_quarter - 1)
                # for t/t_1 using "unvintaged" data from T
                df_t_1 = df[1:findfirst(x -> x == iterate_quarters(t_1, -1), df[:date]), :]
                df_t   = df[1:findfirst(x -> x == iterate_quarters(t,   -1), df[:date]), :]

                # Setting overrides keeps getting carried over across estimations..
                # may need to put this inside the loop.. but that doesn't seem like a great solution.
                setting_overrides = Dict{Symbol, Setting}(:use_chand_recursion => Setting(:use_chand_recursion, true))
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
                               iteration = i, setting_overrides = setting_overrides, verbose = :none,
                               data_override_T = df_t_1, data_override_T_star = df_t)
            end
        end
    end
end

if configure_master_reference
    # Default SMCProject specs
    global est_spec  = 2 #a = 0.98, n_mh = 1        #15 # a = 0.95, n_mh = 1
    global data_spec = 1 # No rate expectations

    models   = OrderedDict{Symbol, AbstractModel}()
    settings = OrderedDict{Symbol, OrderedDict{Symbol, Any}}()

    ################################################################################
    settings[:AnSchorfheide] =
    OrderedDict(
         :model_name      => :AnSchorfheide,
         :iteration_range => 1:200,
         :run_date        => run_date,
         :est_specs_increment_exercise => 2:2, #15:15,
         # These est_specs correspond to 0.0, 0.98, 0.97, 0.95, 0.90, N_MH = 1 respectively
         :T_star          => quartertodate("1991-Q4"),
         :T               => quartertodate("2016-Q4"),
         :alphas          => [0.98], #[0.95],
         :tempers         => [:whole, :plus, :old, :new])

    # Shorter names for convenience
    as = settings[:AnSchorfheide]

    as[:model]      = prepare_model(as[:model_name], 2017, 1, as[:run_date], subspec = "ss0", est_spec = 1, data_spec = 1)
end

if plot_figures
    Ts = quarter_range(as[:T_star], as[:T])
    Ts = Base.filter(x -> Dates.month(x) == 12, Ts) # To get an annual range
    # n_periods = length(Ts)

    exercise_specifications = OrderedDict(:est_specs => as[:est_specs_increment_exercise],
                                          :smc_iteration => as[:iteration_range])
    print_strings = OrderedDict(:est_specs => "est",
                                :smc_iteration => "iter")

    savedir = "../../save/$(run_date)/output_data/an_schorfheide/ss0/estimate/figures"
    if !ispath(savedir)
        mkdir(savedir)
    end
    p1, p2 = plot_mdd_means_and_stds_over_time_nongadfly(as[:model_name], run_date, Ts,
                                               exercise_specifications,
                                               filename_means = "means_over_time_98",
                                               filename_stds = "stds_over_time_98",
                                               plotroot = savedir,
                                               print_strings)

    ps = plot_posterior_means_over_time(as[:model], Ts, exercise_specifications,
                                        plotroot = savedir,
                                        filename_addl = "98", print_strings)

end
