import Base.Iterators: product # Because the product in the Iterators package itself is slow
import Base: squeeze

"""
```
load_smc_statistics_dfs(model, run_date, T_star, T, est_specs;
                        print_strings, tempers)
```

UPDATE

For loading in a Dict{Symbol, DataFrame} of all of the dataframes from the various time tempering specifications, including :whole, :plus, :new, and :old.
The notation used in this function correspond to time tempering where 1:T_star is the shorter sample (:old) and 1:T is the longer sample (:whole), i.e. T > T_star.
Thus, :plus and :new correspond to T_star+1:T, where the only difference between the two is that :plus has the full MDD given by 1:T_star + T_star+1:T, whereas :new only has the T_star+1:T MDD.

### Arguments
- `model::Symbol`: The name of the model, e.g. :Model805.
- `run_date::String`: The date the estimations were run, i.e. what dated save directory the estimations are saved in.
- `T_star::Date`: The "old sample" end date.
- `T::Date`: The "new sample" end date.
- `est_specs::Vector{Int}`: The various SMCProject estimation specifications for the estimations we want to load in.

### Keyword Arguments
- `print_strings::Dict{Symbol, String}`: The model settings that we set to print for the estimations and what string we wanted them to print as, e.g. print_strings = Dict{Symbol, String} = Dict(:adaptive_tempering_target_smc => "adpt"), if we set the model setting, Setting(:adaptive_tempering_target_smc, XYZ, true, "adpt", "Setting description"), during estimation.
- `tempers::Vector{Symbol}`: The various time tempering specifications that we want to output [:whole, :plus, :new, :old].

"""
function load_smc_statistics_dfs(model::Symbol, run_date::String, T::Date,
                                 exercise_specifications::OrderedDict{Symbol},
                                 print_strings::OrderedDict{Symbol, String};
                                 subspec::String = "ss0",
                                 T_star::Date = Date(1),
                                 tempers::Vector{Symbol} = [:whole, :plus, :new, :old],
                                 stats::Vector{Symbol}   = [:mean_logmdd, :std_logmdd,
                                                            :mean_min, :mean_schedlength,
                                                            :mean_resamples]) where S<:Union{Vector{Int}, UnitRange{Int}}
    # The 2017, 1 (year, quarter) arguments don't affect the load-in behavior.
    m = prepare_model(model, 2017, 1, run_date, subspec = subspec, est_spec = 1, data_spec = 1)

    cloud_db = load_clouds(m, T, exercise_specifications,
                           print_strings, outputs = [:clouds, :mdds, :alphas, :n_mhs],
                           tempers = tempers, T_star = T_star)

    dfs = Dict{Symbol, DataFrame}()
    construct_df(x) = construct_smc_statistics_df(cloud_db, x)

    for t_spec in tempers
        dfs[t_spec] = construct_df(t_spec)
    end

    return dfs
end

# New method based on Query.jl!
function construct_smc_statistics_df(cloud_db::DataFrame, temper_type::Symbol)
    df_stats = @from i in cloud_db begin
                   @where i.temper_type == temper_type
                   @group i by i.est_specs into g
                   @select {est_spec = key(g),
                            alpha     = unique(g.alphas)[1],
                            nmh       = unique(g.n_mhs)[1],
                            mean_logmdd = mean(g.mdds),
                            std_logmdd  = std(g.mdds),
                            mean_min    = mean(map(x -> x.total_sampling_time/60, g.clouds)),
                            std_min     = std(map(x -> x.total_sampling_time/60, g.clouds)),
                            mean_schedlength = mean(map(x -> x.stage_index, g.clouds)),
                            std_schedlength  = std(map(x -> x.stage_index, g.clouds)),
                            mean_resamples   = mean(map(x -> x.resamples, g.clouds)),
                            std_resamples    = std(map(x -> x.resamples, g.clouds))}
                   @collect DataFrame
               end

    return df_stats
end
