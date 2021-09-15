# Map from the model name, AnSchorfheide, Model1002, etc. to the setting updating function
const model_setting_update_mapping = Dict{Symbol, Function}(:AnSchorfheide => update_AnSchorfheide_settings,
                                                            :SmetsWoutersOrig  => update_SmetsWoutersOrig_settings,
                                                            :SmetsWouters => update_SmetsWouters_settings,
                                                            :Model805 => update_Model805_settings,
                                                            :Model904 => update_Model904_settings)

# Map from spec(m) to setting updating function
const model_spec_setting_update_mapping = Dict{String, Function}("an_schorfheide" => update_AnSchorfheide_settings,
                                                                 "smets_wouters_orig" => update_SmetsWoutersOrig_settings,
                                                                 "smets_wouters" => update_SmetsWouters_settings,
                                                                 "m805" => update_Model805_settings,
                                                                 "m904" => update_Model904_settings)

# est_spec will have the SMC settings, like n_particles, lambda, n_blocks, etc.
# fcast_spec will have the number of periods the pred density is averaged over (4-period average, or single period)
function initialize_default_settings(model::Symbol, year::Int, quarter::Int, estimation_date::String;
                                     data_spec::Int = 0, est_spec::Int = 0,
                                     fcast_spec::Int = 0, plot_spec::Int = 0,
                                     verbose::Symbol = :low)
    # Construct the vintage
    vintage = forecast_vintage(year, quarter)

    # General settings
    general_settings = Dict{Symbol, Setting}(:settings_spec => Setting(:settings_spec, :general))

    # General settings
    general_settings[:sampling_method]      = Setting(:sampling_method, :MH)
    general_settings[:use_parallel_workers] = Setting(:use_parallel_workers, true)
    general_settings[:resampler_smc]        = Setting(:resampler_smc, :systematic)

    general_settings[:data_vintage] = Setting(:data_vintage, vintage)
    general_settings[:saveroot]     = Setting(:saveroot, "$SMC_DIR/save/"*estimation_date)
    general_settings[:dataroot]     = Setting(:dataroot, "$SMC_DIR/save/input_data")

    general_settings[:date_forecast_start]  = Setting(:date_forecast_start, DSGE.quartertodate("$year-Q$quarter"))
    general_settings[:date_conditional_end] = Setting(:date_conditional_end, DSGE.quartertodate("$year-Q$quarter"))

    data_settings = update_data_settings(data_spec, year, quarter; default_setting = true, verbose = verbose)

    # Model-specific settings
    _update_model_settings = model_setting_update_mapping[model]
    est_settings, fcast_settings, plot_settings =  _update_model_settings(est_spec, fcast_spec, plot_spec,
                                                                          default_setting = true,
                                                                          verbose = verbose)

    default_settings = construct_default_settings(general_settings, data_settings, est_settings,
                                                  fcast_settings, plot_settings)

    return default_settings
end

function update_data_settings(data_spec::Int = 0, year::Int = 0, quarter::Int = 0;
                              default_setting::Bool = false,
                              verbose::Symbol = :low)

    data_settings   = Dict{Symbol, Any}()

    # Data settings
    if data_spec == 0
        nothing
    elseif data_spec == 1 # No rate expectations
        data_settings[:hpfilter_population] = true
        data_settings[:rate_expectations_source] = :none
        data_settings[:rate_expectations_post_liftoff] = false
        data_settings[:use_population_forecast] = true
        data_settings[:use_staff_forecasts] = true
    elseif data_spec == 2 # OIS rate expectations
        data_settings[:n_anticipated_shocks] = 6
        data_settings[:hpfilter_population] = true
        data_settings[:rate_expectations_source] = :ois
        data_settings[:rate_expectations_post_liftoff] = false
        data_settings[:use_population_forecast] = true
        data_settings[:use_staff_forecasts] = true
    elseif data_spec == 3 # No rate expectations, no population forecast, no staff forecasts
        data_settings[:hpfilter_population] = true
        data_settings[:rate_expectations_source] = :none
        data_settings[:rate_expectations_post_liftoff] = false
        data_settings[:use_population_forecast] = false
        data_settings[:use_staff_forecasts] = false
    elseif data_spec == 4 # Bluechip rate expectations
        data_settings[:n_anticipated_shocks] = 6
        data_settings[:hpfilter_population] = true
        data_settings[:rate_expectations_source] = :bluechip
        data_settings[:rate_expectations_post_liftoff] = true
        data_settings[:use_population_forecast] = true
        data_settings[:use_staff_forecasts] = true
    else
        error("Invalid data_spec: $data_spec")
    end

    if data_spec == 0
        if VERBOSITY[verbose] >= VERBOSITY[:low]
            if default_setting
                throw("Must initialize data_spec to an actual specification, i.e. data_spec != 0 when initializing default settings.")
            else
                println("Data settings unchanged. data_spec = $data_spec")
            end
        end
    else
        if VERBOSITY[verbose] >= VERBOSITY[:low]
            if default_setting
                println("Data setting initialized to: data_spec = $data_spec")
            else
                println("Data settings updated to: data_spec = $data_spec")
            end
        end
    end

    data_model_settings = interpret_data_settings_as_model_settings(data_settings, year, quarter)

    return data_model_settings
end

# Because certain data settings are not DSGE model settings
# we need an intermediary function that maps the data setting to
# the model settings relevant to implementing that data setting.
function interpret_data_settings_as_model_settings(data_settings::Dict{Symbol, Any}, year::Int, quarter::Int)
    data_model_settings = Dict{Symbol, Setting}(:settings_spec => Setting(:settings_spec, :data))

    # Populate the implied model settings from the data settings
    data_model_settings[:n_anticipated_shocks] =
    if data_settings[:rate_expectations_source] == :none
            Setting(:n_anticipated_shocks, 0)
    elseif data_settings[:rate_expectations_source] in [:ois, :bluechip]
        if (year, quarter) <= (2008, 4)
            # If first forecast quarter is <= 2008-Q4, then last data period is <= 2008-Q3,
            # hence there is no rate expectations data
            Setting(:n_anticipated_shocks, 0)
        else
            Setting(:n_anticipated_shocks, 6)
        end
    end

    # Also save data settings that are not explicitly model settings
    # for use in load_realtime_data wrapper
    for key in keys(data_settings)
        data_model_settings[key] = Setting(key, data_settings[key])
    end

    return data_model_settings
end

function construct_default_settings(general_settings::Dict,
                                    data_settings::Dict, est_settings::Dict,
                                    fcast_settings::Dict, plot_settings::Dict)
    @assert general_settings[:settings_spec].value == :general "Must pass in the general_settings dictionary as the first argument"
    @assert data_settings[:settings_spec].value    == :data    "Must pass in the data_settings dictionary as the second argument"
    @assert est_settings[:settings_spec].value     == :est     "Must pass in the est_settings dictionary as the third argument"
    @assert fcast_settings[:settings_spec].value   == :fcast   "Must pass in the fcast_settings dictionary as the fourth argument"
    @assert plot_settings[:settings_spec].value    == :plot    "Must pass in the plot_settings dictionary as the fifth argument"

    default_settings = Dict{Symbol, Setting}()
    settings_list = [general_settings, data_settings, est_settings, fcast_settings, plot_settings]
    for settings in settings_list
        for key in setdiff(keys(settings), [:settings_spec])
            default_settings[key] = settings[key]
        end
    end
    return default_settings
end

function update_model_settings!(m::AbstractModel; data_spec::Int = 0,
                                est_spec::Int = 0, fcast_spec::Int = 0, plot_spec::Int = 0,
                                verbose::Symbol = :low)

    data_settings = update_data_settings(data_spec, verbose = verbose)

    _update_model_settings = model_spec_setting_update_mapping[m.spec]
    est_settings, fcast_settings, plot_settings = _update_model_settings(est_spec, fcast_spec, plot_spec,
                                                                         verbose = verbose)

    custom_settings = Dict{Symbol, Setting}()
    settings_list = [data_settings, est_settings, fcast_settings, plot_settings]
    for settings in settings_list
        for key in setdiff(keys(settings), [:settings_spec])
            custom_settings[key] = settings[key]
        end
    end

    # custom setting overrides
    map(s -> m <= s, values(custom_settings))

    nothing
end
