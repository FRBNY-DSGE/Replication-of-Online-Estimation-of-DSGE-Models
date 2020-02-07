function realtime_rmse_plots(model::Symbol, reference_forecast::Symbol,
                             input_type::Symbol, cond_type::Symbol,
                             compareto::Symbol; subspec::String = "",
                             enforce_zlb::Symbol = :default,
                             average::Bool = false, q4q4::Bool = false,
                             kwargs...)
    # Compute RMSEs
    base_rmses, comp_rmses, ns = realtime_rmse(model, reference_forecast,
                                               input_type, cond_type, compareto,
                                               subspec = subspec,
                                               enforce_zlb = enforce_zlb,
                                               average = average, q4q4 = q4q4)

    # Get series attributes
    base_styles = (string(model), :red, :solid, :circle)
    comp_styles = if compareto == :reference
        (reference_forecast_longname(reference_forecast),
         reference_forecast_color(reference_forecast),
         :solid, :diamond)
    else
        error("Pseudo-realtime RMSEs must be computed relative to reference forecast")
    end

    # Get output file names
    filestrs = OrderedDict{Symbol, Any}()
    filestrs[:bdd]   = enforce_zlb
    filestrs[:cond]  = cond_type
    filestrs[:est]   = EST_SPEC
    filestrs[:fcast] = FCAST_SPEC
    filestrs[:para]  = input_type
    filestrs[:plot]  = PLOT_SPEC

    filenames = Dict{Symbol, String}()
    for var in union(keys(base_rmses), keys(comp_rmses))
        filename = if average
            "avgrmse_" * string(var) * ".pdf"
        else
            "rmse_" * string(var) * ".pdf"
        end

        filenames[var] = figurespath(model, "forecast", filename, subspec = subspec,
                                     filestrs = filestrs, saveroot = saveroot)
    end

    # Plot
    rmse_plots(base_rmses, comp_rmses, base_styles, comp_styles, reference_forecast, ns;
               average = average, q4q4 = q4q4, filenames = filenames, kwargs...)
end
