import DSGE: quarter_range

# Go from high-level to low-level

"""

For loading clouds with a set of `exercise_specifications` from a SET of vintages (flexibly defined to grab time tempered results).
The vintage information of the model object being passed will not be referenced.

### Arguments
- `m::AbstractModel`: A "blank" model object. Just needed for the saveroot and methods defined on models for grabbing paths.
- `T_star::Date`: The first forecast quarter corresponding to the initial sample that was estimated in a time tempered estimation. e.g. the p(y_{1:T*}), s.t. p(y_{1:T}) ∝ p(y_{T*+1:T}|y_{1:T*}) p(y_{1:T*})
- `T::Date`: The final first forecast quarter corresponding to the portion of the sample being tempered in during a time tempered estimation (reference notation from T_star note).

### Keyword Arguments
- `T_star1::Date`: The first forecast quarter preceding T_star, in the event that the initial sample, y_{1:T*} was not estimated from scratch, but was itself tempered from a previous cloud.

"""
function load_clouds(m_input::AbstractModel, T::Date,
                     exercise_specifications::OrderedDict{Symbol},
                     print_strings::OrderedDict{Symbol, String};
                     outputs::Vector{Symbol} = [:clouds, :mdds, :alphas],
                     tempers::Vector{Symbol} = [:whole, :plus, :new, :old],
                     T_star::Date = Date(1), T_star1::Date = Date(1),
                     setting_overrides::Dict{Symbol, Setting} = Dict{Symbol, Setting}())
    # To not alter actual settings in the model being passed in
    m = deepcopy(m_input)

    # Set the forecast vintage for T
    T_vint      = forecast_vintage(T)

    # If the only temper type you want to load in is "old" but
    # the T_star is not specified, then by default assume that the date
    # intended to be the "old" first forecast quarter is given by T
    if tempers == [:old] && T_star == Date(1)
        T_star = T
    end

    db_full = DataFrame()

    # Loading in "whole" - p(y_{1:T})
    if :whole in tempers
        setting_overrides[:data_vintage] = Setting(:data_vintage, T_vint, true, "vint", "The current vintage tempered up until")
        db_whole = load_clouds(m, exercise_specifications, print_strings,
                               outputs = outputs, label_key = :temper_type, label_value = :whole,
                               setting_overrides = setting_overrides)
        if isempty(db_full)
            db_full = deepcopy(db_whole)
        else
            db_full = vcat(db_full, db_whole)
        end
    end

    # Loading in "old" - p(y_{1:T*})
    if !isempty(intersect([:plus, :old], tempers))
        # If we are loading in :old then set the forecast vintage for T_star
        T_star_vint = forecast_vintage(T_star)

        if T_star1 != Date(1)
            setting_overrides[:previous_vintage] = Setting(:previous_vintage, forecast_vintage(T_star1), true, "prev", "The previous vintage to be tempered in")
        end
        setting_overrides[:data_vintage] = Setting(:data_vintage, T_star_vint, true, "vint", "The current vintage tempered up until")
        db_old = load_clouds(m, exercise_specifications, print_strings,
                             outputs = outputs, label_key = :temper_type, label_value = :old,
                             setting_overrides = setting_overrides)
        if isempty(db_full)
            db_full = deepcopy(db_old)
        else
            db_full = vcat(db_full, db_old)
        end
    end

    # Loading in "new" - p(y_{T*+1:T}|y_{1:T*})
    if !isempty(intersect([:plus, :new], tempers))
        T_star_vint = forecast_vintage(T_star)

        setting_overrides[:previous_vintage] = Setting(:previous_vintage, T_star_vint, true, "prev", "The previous vintage to be tempered in")
        setting_overrides[:data_vintage]     = Setting(:data_vintage, T_vint, true, "vint", "The current vintage tempered up until")
        db_new = load_clouds(m, exercise_specifications, print_strings,
                             outputs = outputs, label_key = :temper_type, label_value = :new,
                             setting_overrides = setting_overrides)
        if isempty(db_full)
            db_full = deepcopy(db_new)
        else
            db_full = vcat(db_full, db_new)
        end
    end

    # Calculating "plus" - p(y_{T*+1:T}|y_{1:T*})p(y_{1:T*})
    if :plus in tempers
        db_plus = deepcopy(db_new)
        db_plus[!, :mdds] = db_old[:, :mdds] + db_new[:, :mdds]
        db_plus[:temper_type] .= :plus

        if isempty(db_full)
            db_full = deepcopy(db_plus)
        else
            db_full = vcat(db_full, db_plus)
        end
    end

    return db_full
end

"""

For loading clouds with a set of `exercise_specifications` from a SINGLE vintage (whatever is the vintage currently
set in the model object) with filestrings to be printed given by `print_strings`.

### Arguments
- `m::AbstractModel`: Needed for the vintage, saveroot, and for the methods defined on models for grabbing paths.
- `exercise_specifications::Dict{Symbol}`: A dictionary mapping a model setting key to a vector/unitrange of values to be iterated over.
e.g. Dict(:adaptive_tempering_target_smc => [0.90, 0.95, 0.97], :smc_iteration => collect(1:20))
- `print_strings::Dict{Symbol, String}`: A dictionary mapping a model setting key to the filestring for printing.
e.g. Dict(:adaptive_tepmering_target_smc => "adpt")

### Keyword Arguments
- `outputs::Vector{Symbol}`: The outputs to return in the DataFrame returned by load_clouds. Choose a subset of [:clouds, :mdds, :alphas, :n_mhs].
- `label_key/label_value::Symbol`: The column name, `label_key`, for an optional additional column (filled with values given by `label_value`) meant to label this DataFrame. Useful for creating multiple dataframes with different labels, e.g. label_key = :time_temper, label_value = :old
- `setting_overrides::Dict{Symbol, Setting}`: A dictionary of setting overrides applied to the model right before loading the output, and hence overriding any default settings.

### Return
`db::DataFrame`: A database-style dataframe containing particle clouds and mdds as the values and other relevant info as additional columns.

"""
function load_clouds(m_input::AbstractModel,
                     exercise_specifications::OrderedDict{Symbol},
                     print_strings::OrderedDict{Symbol, String};
                     outputs::Vector{Symbol} = [:clouds, :mdds, :alphas],
                     label_key::Symbol = Symbol(), label_value::Symbol = Symbol(),
                     setting_overrides::Dict{Symbol, Setting} = Dict{Symbol, Setting}())
    # To not alter actual settings in the model being passed in
    m = deepcopy(m_input)

    # These should be the same (and in the same order),
    @assert isequal(collect(keys(exercise_specifications)), collect(keys(print_strings)))

    # A model_setting_key is what it sounds like, e.g. :adaptive_tempering_target_smc
    model_setting_keys = keys(exercise_specifications)

    # Initialize return arguments
    db = DataFrame(est_specs = Int[])
    if :alphas in outputs
        db = hcat(db, DataFrame(alphas = Float64[]))
    end
    if :n_mhs in outputs
        db = hcat(db, DataFrame(n_mhs = Int[]))
    end
    if :clouds in outputs
        db = hcat(db, DataFrame(clouds = Union{SMC.Cloud, ParticleCloud}[])) #ParticleCloud[]))
    end
    if :mdds in outputs
        db = hcat(db, DataFrame(mdds = Float64[]))
    end

    # Assume we want to load in output with printed setting values
    # given by the cartesian product of `exercise_specifications`
    # E.g. :est_spec X :smc_iteration
    # `exercise_spec` variable at each iteration will be one
    # concrete combination of setting values, like (5, 1)
#    @show model_setting_keys
#    @show exercise_specifications
    for exercise_spec in product(values(exercise_specifications)...)
#        @show exercise_spec
        #= for (model_setting_key, model_setting_value) in zip(model_setting_keys, exercise_spec)
            @show model_setting_key, model_setting_value
            if haskey(db, model_setting_key)
                push!(db[model_setting_key], model_setting_value)
            else
                db[model_setting_key] = model_setting_value
            end

            model_setting_filestring = print_strings[model_setting_key]

            # Print set the setting and print it with the designated filestring
            m <= Setting(model_setting_key, model_setting_value, true, model_setting_filestring, "")
        end=#

        # Setting up the model to construct the correct filestring_base with the right setting values
        for (i, model_setting_key) in enumerate(model_setting_keys)
            model_setting_filestring = print_strings[model_setting_key]
            # Print set the setting and print it with the designated filestring
            m <= Setting(model_setting_key, exercise_spec[i], true, model_setting_filestring, "")
        end
        est_spec_setting_value = exercise_spec[1]

        # Fill the database with clouds/mdds
        alpha = model_spec_setting_update_mapping[spec(m)](est_spec_setting_value, 0, 0;
                                verbose = :none)[1][:adaptive_tempering_target_smc].value
        n_mh = model_spec_setting_update_mapping[spec(m)](est_spec_setting_value, 0, 0;
                                verbose = :none)[1][:n_mh_steps_smc].value
        if (:clouds in outputs) || (:mdds in outputs)
            cloud, mdd = load_all_smc_outputs(m, setting_overrides = setting_overrides)
        end

        if hasproperty(db, :alphas) && hasproperty(db, :n_mhs) &&
            hasproperty(db, :clouds) && hasproperty(db, :mdds)
            push!(db, [est_spec_setting_value, alpha, n_mh, cloud, mdd])
        elseif hasproperty(db, :alphas) && hasproperty(db, :clouds) && hasproperty(db, :mdds)
            push!(db, [est_spec_setting_value, alpha, cloud, mdd])
        elseif hasproperty(db, :alphas) && hasproperty(db, :clouds)
            push!(db, [est_spec_setting_value, alpha, cloud])
        elseif hasproperty(db, :clouds)
            push!(db, [est_spec_setting_value, cloud])
        elseif hasproperty(db, :mdds)
            push!(db, [est_spec_setting_value, mdd])
        end
    end

    # Additional important labels for the database!
    db[!,:model_name] = fill(spec(m), size(db, 1))

    # Provide an optional addl label (like the :temper_type for time tempered results).
    # Useful when using this method to load in a subset of the full set of results
    if label_key != Symbol() && label_value != Symbol()
        db[!,label_key] = fill(label_value, size(db, 1))
    end

    return db
end

# Base level methods
function load_all_smc_outputs(m_input::AbstractModel;
                              setting_overrides::Dict{Symbol, Setting} = Dict{Symbol, Setting}())
    # To not alter actual settings in the model being passed in
    m = deepcopy(m_input)

    if !isempty(setting_overrides)
        map(s -> m <= s, values(setting_overrides))
    end

    out = load(rawpath(m, "estimate", "smc_cloud.jld2"))

    cloud = out["cloud"]

    w_W = out["w"][:, 2:end] .* out["W"][:, 1:end-1]
    mdd = sum(log.(sum(w_W, dims=1)))

    return cloud, mdd
end

function load_cloud(m_input::AbstractModel;
                    setting_overrides::Dict{Symbol, Setting} = Dict{Symbol, Setting}())
    # To not alter actual settings in the model being passed in
    m = deepcopy(m_input)

    if !isempty(setting_overrides)
        map(s -> m <= s, values(setting_overrides))
    end

    load(rawpath(m, "estimate", "smc_cloud.jld2"), "cloud")
end

function load_mdd(m_input::AbstractModel;
                  setting_overrides::Dict{Symbol, Setting} = Dict{Symbol, Setting}())
    # To not alter actual settings in the model being passed in
    m = deepcopy(m_input)

    if !isempty(setting_overrides)
        map(s -> m <= s, values(setting_overrides))
    end

    return marginal_data_density(m)
end
