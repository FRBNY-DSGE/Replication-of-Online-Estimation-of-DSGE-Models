# Top to bottom is from highest level to lowest level
function plot_predictive_density_grid(logscores::Matrix{Float64};
                                      plots_per_row::Int = 8,
                                      seriescolor::Symbol = :blue,
                                      filepath::String = "",
                                      plot_size::Tuple = (3000, 3000))
    plot_predictive_density_grid_comparison([logscores]; plots_per_row = plots_per_row,
                                            filepath = filepath, plot_size = plot_size,
                                            colors_set = [seriescolor])
end

function plot_predictive_density_over_time(logscores::Matrix{Float64},
                                           T0::Date, T::Date;
                                           seriescolor::Symbol = :black,
                                           xticks::OrdinalRange = Dates.year(T0):2:Dates.year(T),
                                           ylims::Tuple  = Tuple{}(),
                                           legend_location::Symbol = :bottomleft,
                                           label::String = "",
                                           title::String = "",
                                           filepath::String = "")
    plot_predictive_density_over_time_comparison([logscores], T0, T; colors_set = [:black],
                                                 xticks = xticks, ylims = ylims, legend_location =
                                                 legend_location, labels = [label], title = title,
                                                 filepath = filepath)
end

function plot_predictive_density_grid_comparison(logscores_set::Vector{Matrix{Float64}};
                                                 plots_per_row::Int = 8,
                                                 # seriescolors::Vector{Symbol} = :blue,
                                                 filepath::String = "",
                                                 plot_size::Tuple = (3000, 3000),
                                                 colors_set::Vector{Symbol} =
                                                 [:blue, :red, :green, :purple])
    # Figure out the number of horizons being plotted
    n_set      = length(logscores_set)
    n_horizons = size(logscores_set[1], 2)
    for (i, logscores) in enumerate(logscores_set)
        @assert size(logscores, 2) == n_horizons "Logscores must all have the same number of horizons to be compared. Logscore $i is malformed."
    end

    # To make it easier to generalize in the future if need be
    kdes_set = Vector{Vector{UnivariateKDE}}(undef, n_set)
    ps_set   = Vector{Plots.Plot}(undef, n_horizons)

    for i in 1:n_set
        kdes_set[i] = Vector{UnivariateKDE}(undef, n_horizons)
    end

    # Calculate the KDEs and set the xlims and ylims adaptively
    # based on the support and maximum density of the KDEs
    min_logscore = floor(minimum(map(x -> minimum(x), logscores_set))) - 1
    max_density  = 0.
    for i in 1:n_set
        for j in 1:n_horizons
            kdes_set[i][j] = kde(logscores_set[i][:, j], boundary = (min_logscore, 0))
        end
        max_density = max(max_density, maximum(map(x -> maximum(x.density), kdes_set[i])))
    end
    max_density = ceil(max_density) + 1

    # (WIP) Need to find a better way to populate series colors..
    # For now do it the dumb way and just make a long list of colors
    @assert length(colors_set) >= n_set "Add more colors to the color_set"

    for j in 1:n_horizons
        for i in 1:n_set
            seriescolor  = colors_set[i]
            if i == 1
                ps_set[j] = Plots.plot(kdes_set[i][j], ylims = (0, max_density), label = "",
                                 fill = (0, 0.2, seriescolor), seriescolor = seriescolor)
            else
                Plots.plot!(ps_set[j], kdes_set[i][j], ylims = (0, max_density), label = "",
                      fill = (0, 0.2, seriescolor), seriescolor = seriescolor)
            end
        end
    end

    # Determine the grid layout
    plots_per_column = ceil(Int, n_horizons/plots_per_row)

    # Pad ps_set with empty plots to be able to generate a well-formed
    # (plots_per_column grid x plots_per_row)
    for i in 1:(plots_per_row * plots_per_column - n_horizons)
        push!(ps_set, plot())
    end

    p_all = Plots.plot(ps_set..., size = plot_size, layout = (plots_per_column, plots_per_row))

    if !isempty(filepath)
        savefig(p_all, "$filepath")
    end

    return p_all
end

function plot_predictive_density_over_time_comparison(base_model::Symbol, comp_model::Symbol,
                                                      base_subspec::String,
                                                      comp_subspec::String,
                                                      T0::Date, T::Date,
                                                      input_type::Symbol, cond_type::Symbol,
                                                      horizon::Int, data_spec::Int,
                                                      load_date::String,
                                                      base_est_spec::Int, comp_est_spec::Int;
                                                      sampling_method::Symbol = :SMC,
                                                      point_forecast::Bool = false,
                                                      plot_start_date::Date = T0,
                                                      plot_end_date::Date = T,
                                                      colors_set::Vector{Symbol} =
                                                      [:blue, :red, :green, :purple],
                                                      xticks::OrdinalRange =
                                                      Dates.year(plot_start_date):2:Dates.year(plot_end_date),
                                                      ylims::Tuple = Tuple{}(),
                                                      legend_location::Symbol = :bottomleft,
                                                      margin::Measure = 7mm,
                                                      labels::Vector{String} = fill("", 2),
                                                      title::String = "",
                                                      plotroot::String = "",
                                                      save_aux_dir::String = "",
                                                      save_aux_subdir::String = "",
                                                      filestring_ext::String = "")
    base_logscores = load_predictive_densities(base_model, T0, T,
                                               input_type, cond_type, horizon,
                                               load_date, sampling_method;
                                               point_forecast = point_forecast,
                                               subspec = base_subspec, data_spec = data_spec,
                                               est_spec = base_est_spec, save_aux_dir = save_aux_dir)

    comp_logscores = load_predictive_densities(comp_model, T0, T,
                                               input_type, cond_type, horizon,
                                               load_date, sampling_method;
                                               point_forecast = point_forecast,
                                               subspec = comp_subspec, data_spec = data_spec,
                                               est_spec = comp_est_spec, save_aux_dir = save_aux_dir)

    p = plot_predictive_density_over_time_comparison([base_logscores, comp_logscores], T0, T,
                                                     plot_start_date = plot_start_date,
                                                     plot_end_date   = plot_end_date,
                                                     colors_set      = colors_set,
                                                     xticks = xticks, ylims = ylims,
                                                     legend_location = legend_location,
                                                     margin = margin, labels = labels,
                                                     title = title)

    if !isempty(plotroot) && !isempty(filestring_ext)
        if point_forecast
            savefig(p, joinpath(plotroot, save_aux_dir, save_aux_subdir,"grouped_mean_point_pred_dens_$(filestring_ext)_hor=$(horizon)_T0=$(plot_start_date)_T=$(plot_end_date).pdf"))
            println("Saved "*joinpath(plotroot, save_aux_dir, save_aux_subdir,"grouped_mean_point_pred_dens_$(filestring_ext)_hor=$(horizon)_T0=$(plot_start_date)_T=$(plot_end_date).pdf"))
        else
            savefig(p, joinpath(plotroot, save_aux_dir, save_aux_subdir,"grouped_mean_pred_dens_$(filestring_ext)_hor=$(horizon)_T0=$(plot_start_date)_T=$(plot_end_date).pdf"))
            println("Saved "*joinpath(plotroot, save_aux_dir, save_aux_subdir,"grouped_mean_pred_dens_$(filestring_ext)_hor=$(horizon)_T0=$(plot_start_date)_T=$(plot_end_date).pdf"))
        end
    end

    return p
end

# Base method
function plot_predictive_density_over_time_comparison(logscores_set::Vector{Matrix{Float64}},
                                                      T0::Date, T::Date;
                                                      plot_start_date::Date = T0,
                                                      plot_end_date::Date = T,
                                                      colors_set::Vector{Symbol} =
                                                      [:blue, :red, :green, :purple],
                                                      xticks::OrdinalRange =
                                                      Dates.year(plot_start_date):2:Dates.year(plot_end_date),
                                                      ylims::Tuple  = Tuple{}(),
                                                      legend_location::Symbol = :bottomleft,
                                                      margin::Measure = 7mm,
                                                      labels::Vector{String} = fill("", length(logscores_set)),
                                                      title::String = "")
    n_set      = length(logscores_set)
    date_range = quarter_range(plot_start_date, plot_end_date)
    date_range_nums = map(x -> quarter_date_to_number(x), date_range)

    @assert plot_start_date >= T0
    @assert plot_end_date   <= T
    plot_start_ind  = DSGE.subtract_quarters(plot_start_date, T0) + 1
    plot_end_ind    = DSGE.subtract_quarters(plot_end_date, T0) + 1

    for (i, logscores) in enumerate(logscores_set[2:end])
        @assert size(logscores, 2) == size(logscores_set[1], 2) "Logscores must all have the same number of horizons to be compared. Logscore $i is malformed."
    end

    # (WIP) Need to find a better way to populate series colors..
    # For now do it the dumb way and just make a long list of colors
    @assert length(colors_set) >= n_set "Add more colors to the color_set"

    p = Plots.plot(;xticks = xticks, ylims = ylims, title = title, margin = margin)
    for (i, logscores) in enumerate(logscores_set)
        mean_logscores = vec(mean(logscores, dims = 1))
        mean_logscores = mean_logscores[plot_start_ind:plot_end_ind]
        seriescolor = colors_set[i]

        Plots.plot!(p, date_range_nums, mean_logscores,
              seriescolor = seriescolor, legend = legend_location,
              label = labels[i])
    end

    return p
end

"""
```
plot_time_averaged_predictive_density_comparison(base_model, comp_model, base_subspec,
comp_subspec, cond_type, predicted_variables, horizons, start_date, end_date,
load_date, sampling_method, data_spec, base_est_spec, comp_est_spec; plot_start_date =
start_date, plot_end_date = end_date, base_label = "", comp_label = "", base_model_string =
string(base_model), comp_model_string = string(comp_model), base_color = :blue, comp_color =
:red, ylims = (), plotroot = "", save_aux_dir = "", save_aux_subdir = "", kwargs...)
```
Plot predicted densities from two models (`base_model` and `comp_model`) averaged over a
horizon, h, over a set of draws, θ_i, and over time, T0 through T.

Formulaically: p(̄y_{t+h, h}) = ∑_{t=T_0}^T p(̄y_{t+h, h} | I_t) ≡ ∑_{t=T_0}^T ∑_{i=1}^N p(̄y_{t+h,
h} | θ_i, I_t), where p(̄y_{t+h, h} | ⋅) is short-hand for ∑_{i=1}^h p(y_{t+i} | ⋅ ).

### Arguments:
- `base_model/comp_model::Symbol`: The two models being compared in the predictive density
plot.
- `base_subspec/comp_subspec::String`: The subspecs of the two models being compared in the
predictive density plot.
- `cond_type::Symbol`: The conditional type of the forecasts used in calculating the
predictive densities.
- `predicted_variables::Vector{Symbol}`: The observables for which the predictive densities
are calculated, i.e. which variables are forecast.
- `horizons::Union{Vector, AbstractRange}`: The various horizons, `h`, for which forecasts
are averaged.
- `start_date/end_date::Date`: The start date and end date for the logscores that were calculated for each of the
models. Note, this is different than the `plot_start_date/plot_end_date`, which optionally
subsets the date range for the plot.
- `load_date::String`: The vintage from which the predictive densities are loaded.
- `sampling_method::Symbol`: Either :SMC or :MH, the two sampling methods we currently have.
- `data_spec::Int`: The data specification. All of the data specifications are listed in
settings.jl.
- `base_est_spec/comp_est_spec::Int`: The estimation specification. All of the estimation specifications are
listed in settings.jl.

### Keyword Arguments:
- `plot_start_date/plot_end_date::Date`: The date from which you want to start/end plotting, not to be
confused with `start_date`/`end_date`, which are the date range in which the logscores were
calculated.
- `base_label/comp_label::String`: The plot label for the base and comparison (comp) model.
- `base_model_string/comp_model_string`: Shortened string names for the base and comp
models, to be used in the filename. If not provided, defaults to the model's spec.

"""
function plot_time_averaged_predictive_density_comparison(base_model::Symbol, comp_model::Symbol,
                                                          base_subspec::String, comp_subspec::String,
                                                          cond_type::Symbol,
                                                          predicted_variables::Vector{Symbol},
                                                          horizons::S,
                                                          start_date::Date, end_date::Date,
                                                          load_date::String,
                                                          sampling_method::Symbol,
                                                          data_spec::Int,
                                                          base_est_spec::Int,
                                                          comp_est_spec::Int;
                                                          point_forecast::Bool = false,
                                                          plot_start_date::Date = start_date,
                                                          plot_end_date::Date   = end_date,
                                                          comp_load_date::String = load_date,
                                                          comp_sampling_method::Symbol = sampling_method,
                                                          base_label::String = "",
                                                          comp_label::String = "",
                                                          base_model_string::String = string(base_model),
                                                          comp_model_string::String = string(comp_model),
                                                          base_color::Symbol = :blue,
                                                          comp_color::Symbol = :red,
                                                          base_linestyle::Symbol = :solid,
                                                          comp_linestyle::Symbol = :solid,
                                                          ylims::Tuple = (),
                                                          plotroot::String = "",
                                                          save_aux_dir::String = "",
                                                          save_aux_subdir::String = "",
                                                          kwargs...) where S<:Union{Vector, AbstractRange}
    # Load in the logscores
    n_horizons     = length(horizons)
    filestring_ext  = data_spec_and_cond_type_to_filestring(data_spec, cond_type)
    pred_var_string = predicted_variables_to_filestring(predicted_variables)

    full_date_range = quarter_range(start_date, end_date)
    plot_start_ind = findfirst(x -> x == plot_start_date, full_date_range)
    plot_end_ind   = findfirst(x -> x == plot_end_date, full_date_range)

    base_logscores = Vector{Float64}(undef, n_horizons)
    comp_logscores = Vector{Float64}(undef, n_horizons)

    for (i, horizon) in enumerate(horizons)
        base_logscores_all = load_predictive_densities(base_model, start_date, end_date,
                                                       :full, cond_type, horizon,
                                                       load_date, sampling_method;
                                                       point_forecast = point_forecast,
                                                       subspec = base_subspec,
                                                       data_spec = data_spec,
                                                       est_spec  = base_est_spec,
                                                       save_aux_dir = save_aux_dir)
        base_logscores[i] = mean(base_logscores_all[:, plot_start_ind:plot_end_ind])

        comp_logscores_all = load_predictive_densities(comp_model, start_date, end_date,
                                                       :full, cond_type, horizon,
                                                       comp_load_date, comp_sampling_method;
                                                       point_forecast = point_forecast,
                                                       subspec = comp_subspec,
                                                       data_spec = data_spec,
                                                       est_spec  = comp_est_spec,
                                                       save_aux_dir = save_aux_dir)
        comp_logscores[i] = mean(comp_logscores_all[:, plot_start_ind:plot_end_ind])
    end

    # Constructing the ns
    # Because we picked all the data (FFR expectations, horizon etc) to be able to
    # have a fully saturated sample for all horizons, all of the ns for all horizons
    # is the full length of the sample (time_avg_end_date - time_avg_start_date + 1)
    ntickvalues = fill(DSGE.subtract_quarters(plot_end_date, plot_start_date) + 1, length(horizons))
    nticklabels = Vector{String}(undef, length(horizons))
    for (i, h, v) in zip(1:length(horizons), horizons, ntickvalues)
        nticklabels[i] = "$h\nN = $v"
    end

    p = plot_time_averaged_predictive_density_comparison(base_logscores, comp_logscores,
                                                         horizons, nticklabels, base_label = base_label,
                                                         comp_label = comp_label, base_color = base_color,
                                                         comp_color = comp_color,
                                                         base_linestyle = base_linestyle,
                                                         comp_linestyle = comp_linestyle, plotroot = plotroot,
                                                         save_aux_dir = save_aux_dir, ylims = ylims,
                                                         kwargs...)
    # Save figure
    if !isempty(plotroot)
        # Either making a model comparison (base_model != comp_model),
        # or a subspec comparison (base_model == comp_model)
        if !ispath(joinpath(plotroot, save_aux_dir, save_aux_subdir))
            mkpath(joinpath(plotroot, save_aux_dir, save_aux_subdir))
        end
        if base_model != comp_model
            filepath = joinpath(plotroot, save_aux_dir, save_aux_subdir,"time_averaged_$(base_model_string)_vs_$(comp_model_string)_$(filestring_ext)_T0=$(plot_start_date)_T=$(plot_end_date).pdf")
        else
            if sampling_method == comp_sampling_method
                filepath = joinpath(plotroot, save_aux_dir, save_aux_subdir, "time_averaged_$(base_model_string)_prior_comparison_$(filestring_ext)_T0=$(plot_start_date)_T=$(plot_end_date).pdf")
            else
                filepath = joinpath(plotroot, save_aux_dir, save_aux_subdir, "time_averaged_$(base_model_string)_estimation_comparison_$(filestring_ext)_T0=$(plot_start_date)_T=$(plot_end_date).pdf")
            end
        end
        if point_forecast
            filepath = replace(filepath, "time_averaged_"=>"time_averaged_point_")
        end
        savefig(p, filepath)
        println("Saved $filepath")
    end

    return p
end

# Base method
function plot_time_averaged_predictive_density_comparison(base_logscores::Vector{Float64},
                                                          comp_logscores::Vector{Float64},
                                                          horizons::S, nticklabels::Vector{String};
                                                          base_label::String = "",
                                                          comp_label::String = "",
                                                          base_color::Symbol = :blue,
                                                          comp_color::Symbol = :red,
                                                          base_linestyle::Symbol = :solid,
                                                          comp_linestyle::Symbol = :solid,
                                                          plotroot::String = "",
                                                          save_aux_dir::String = "",
                                                          ylims::Tuple = (),
                                                          kwargs...) where {S<:Union{Vector, AbstractRange}}
    p = Plots.plot(horizons, base_logscores, color = base_color, label = base_label, linestyle = base_linestyle,
                   linewidth = 2, markershape = :diamond, markerstrokecolor = base_color,
                   markerstrokewidth = 2, markercolor = :white, margin = 7mm, legend = false,
                   tickfont = font(14), xticks = (horizons, nticklabels), ylims = ylims, kwargs...)
    Plots.plot!(p, horizons, comp_logscores, color = comp_color, label = comp_label, linestyle = comp_linestyle,
                linewidth = 2, markershape = :diamond, markerstrokecolor = comp_color,
                markerstrokewidth = 2, markercolor = :white, margin = 7mm, legend = false,
                tickfont = font(14), kwargs...)

    return p
end
