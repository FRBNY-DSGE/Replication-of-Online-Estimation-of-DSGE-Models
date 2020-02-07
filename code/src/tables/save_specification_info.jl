function save_specification_info(m, n_iterations, T, tableroot; standalone_tex_document::Bool = false)

    filepath = tableroot*"/specification_"*string(get_setting(m, :n_mh_steps_smc))*".tex"
    if m.spec=="smets_wouters_orig"
        model = "Smets Wouters"
    elseif m.spec=="an_schorfheide"
        model = "An Schorfheide"
    else
        model = m.spec
    end
    date_presample_start = get_setting(m, :date_presample_start)
    date_mainsample_start = get_setting(m, :date_mainsample_start)
    date_mainsample_end = get_setting(m, :date_mainsample_end)
    date_presample_end = DSGE.prev_quarter(get_setting(m, :date_mainsample_start))

    open(filepath, "w") do fid
        if standalone_tex_document
            @printf fid "\\documentclass{article}\n\n"
            @printf fid "\\begin{document}\n\n"
        end
        @printf fid "\\subsubsection{Specification} \n \\textbf{Model/SMC Specification}:\\\\ \n \\vspace{-.6cm} \n \\begin{itemize} \n \\item \\textbf{Model}: "
        @printf fid "%s" model
        @printf fid "\n \\item \\textbf{Pre-sample Date Range}: "
        j = 1
        for date in [date_presample_start, date_presample_end]
            @printf fid "%i" Dates.year(date)
            @printf fid "-Q"
            @printf fid "%i" Dates.quarterofyear(date)
            if j%2==1
                @printf fid " through "
            end
            j = j+1
        end
        @printf fid "\n \\item \\textbf{Date Range}: "
j = 1
        for date in [date_mainsample_start, date_mainsample_end]
            @printf fid "%i" Dates.year(date)
            @printf fid "-Q"
            @printf fid "%i" Dates.quarterofyear(date)
            if j%2==1
                @printf fid " through "
            end
            j = j+1
        end
        @printf fid "\n \\item \$T\$ "
        @printf fid "%s" T
        @printf fid "\n \\item \$T^*\$ "
        @printf fid "%i" Dates.year(date_mainsample_end)
        @printf fid "-Q"
        @printf fid "%i" Dates.quarterofyear(date_mainsample_end)
        @printf fid "\n \\item \\textbf{Number of Particles}: "
        @printf fid "%i" get_setting(m, :n_particles)
        @printf fid "\n \\item \\textbf{\$N_\\Phi\$}: "
        @printf fid "%i" get_setting(m, :n_Φ)
        @printf fid "\n \\item \\textbf{\$\\lambda\$}: "
        @printf fid "%g" get_setting(m, :λ)
        @printf fid "\n \\item \\textbf{\$N_{SMC\\_blocks}\$}: "
        @printf fid "%i" get_setting(m, :n_smc_blocks)
        @printf fid "\n \\item \\textbf{\$N_{MH\\_steps}\$}: "
        @printf fid "%i" get_setting(m, :n_mh_steps_smc)
        @printf fid "\n \\item \\textbf{Mixture Proportion}: "
        @printf fid "%g" get_setting(m, :mixture_proportion)
        @printf fid "\n \\item \\textbf{Resampling Threshold}: "
        @printf fid "%g" get_setting(m, :resampling_threshold)
        @printf fid "\n \\item \\textbf{Target Acceptance Rate}: "
        @printf fid "%g" get_setting(m, :target_accept)
        @printf fid "\n \\item \\textbf{Initial Step-Size} (proposal covariance scaling factor): "
        @printf fid "%g" get_setting(m, :step_size_smc)
        @printf fid "\n \\end{itemize} \n "
        if get_setting(m, :adaptive_tempering_target_smc)!=0.0
            @printf fid "\\hspace{-.65cm} \\textbf{Schedule Specification}:\\\\ \n \\vspace{-.6cm} \n \\begin{itemize} \n \\item \\textbf{Fixed Schedule}: With the specified \$N_\\Phi\$ and \$\\lambda\$. \n \\item \\textbf{Adaptive Schedule}: With \$\\alpha = 0.97\$. \n \\item \\textbf{Adaptive Schedule}: With \$\\alpha = 0.98\$. \n \\end{itemize} \n \\hspace{-.65cm} \n"
        end
        @printf fid "\\textbf{Number of estimations at each schedule specification}: "
        @printf fid "%i" n_iterations
        @printf fid "\\\\"
    end
end

#=using DSGE
m = AnSchorfheide()

save_specification(m, 20, "../tables", standalone_tex_document = true)=#