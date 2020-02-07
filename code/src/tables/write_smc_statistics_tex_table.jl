# Top-level method to be called when there ARE time-tempering results
function write_smc_statistics_tex_table(dfs::Dict{Symbol, DataFrame};
                                        drop_fixed::Bool = true,
                                        alphas::Vector{Float64} = [0.0, 0.97, 0.98],
                                        stats::Vector{Symbol} = [:mean_logmdd, :std_logmdd,
                                                                 :mean_min, :mean_schedlength,
                                                                 :mean_resamples],
                                        tempers::Vector{Symbol} = [:plus, :whole],
                                        n_mhs::Vector{Int} = [1],
                                        tableroot::String = tablespath(m, "estimate"),
                                        standalone_tex_document::Bool = false,
                                        filename::String = "")
    drop_fixed_row(x) = x[map(y -> y != 0.0, x[!,:alpha]), :]

    @assert length(tempers) == 2 "For now, we only support a two temper-type smc statistics table comparison"
    df1, df2 = deepcopy(dfs[tempers[1]]), deepcopy(dfs[tempers[2]])
    df1, df2 = drop_fixed_row(df1), drop_fixed_row(df2)

    # Ensure conformity of DataFrames
    try
        vcat(df1, df2)
        df1[!,:alpha] == df2[!,:alpha]
        df1[!,:nmh]   == df2[!,:nmh]
    catch
        throw("`df1` and `df2` are not conformable. Ensure that they have the same column names, and that their alpha and nmh rows are ordered the same.")
    end

    # Construct filepath
    filepath = tableroot*"/"*filename*".tex"

    # Setup alphas
    @assert issubset(alphas, df1[!,:alpha]) "Keyword argument `alphas` is misspecified. Make sure that the entries provided are valid alphas in `df[:alpha]`"
    @assert alphas == unique(alphas)      "Keyword argument `alphas` is misspecified. Do not duplicate alphas in keyword argument `alphas`"
    alphas = sort(unique(alphas))

    # Setup n_mhs
    @assert issubset(n_mhs, df1[!,:nmh]) "Keyword argument `n_mhs` is misspecified. Make sure that the entries provided are valid n_mhs in `df[:nmh]`"
    @assert n_mhs == unique(n_mhs)     "Keyword argument `n_mhs` is misspecified. Do not duplicate n_mhs in keyword argument `n_mhs`"
    n_mhs  = sort(unique(n_mhs))

    open(filepath, "w") do fid
        write_smc_statistics_tex_table_headings(fid, standalone_tex_document = standalone_tex_document,
                                                alphas = alphas, tempers = tempers)

        for n_mh in n_mhs
            # Subset dfs to only include rows pertaining to n_mh
            # and remove the nmh column, since the subsetted dfs now only have
            # entries from a single n_mh
            df1_nmh = df1[df1[!,:nmh] .== n_mh, :]
            df1_nmh = df1_nmh[Base.filter(x -> x != :nmh, names(df1_nmh))]

            df2_nmh = df2[df2[!,:nmh] .== n_mh, :]
            df2_nmh = df2_nmh[Base.filter(x -> x != :nmh, names(df2_nmh))]

            if length(n_mh) > 1
                @printf fid "\\textbf{\$N_{MH}="
                @printf fid "%i" n_mh
                @printf fid "\$ } \\\\ \\hline "
            end

            write_smc_statistics_tex_table(fid, df1_nmh, df2_nmh;
                                           alphas = alphas, stats = stats,
                                           tempers = tempers)
        end

        @printf fid "\\hline \n"
        @printf fid "\\end{tabular}"
        if standalone_tex_document
            @printf fid "\n\\end{document}"
        end
    end
    println("Wrote $filepath")
end

# Top-level method to be called when there ARE NO time-tempering results
function write_smc_statistics_tex_table(df_input::DataFrame;
                                        drop_fixed::Bool = true,
                                        alphas::Vector{Float64} = [0.0, 0.97, 0.98],
                                        stats::Vector{Symbol}   = [:mean_logmdd, :std_logmdd,
                                                                   :mean_min, :mean_schedlength,
                                                                   :mean_resamples],
                                        n_mhs::Vector{Int} = [1],
                                        tableroot::String = tablespath(m, "estimate"),
                                        standalone_tex_document::Bool = false,
                                        filename::String = "")
    drop_fixed_row(x) = x[map(y -> y != 0.0, x[!,:alpha]), :]
    df = deepcopy(df_input)
    if drop_fixed
        df = drop_fixed_row(df)
    end

    # Construct filepath
    filepath = tableroot*"/"*filename*".tex"

    # Setup alphas
    @assert issubset(alphas, sort(unique(df[!,:alpha]))) "Keyword argument `alphas` is misspecified. Make sure that the entries provided are valid alphas in `df[!,:alpha]`"
    alphas = sort(unique(alphas))

    # Setup n_mhs
    @assert issubset(n_mhs, df[!,:nmh]) "Keyword argument `n_mhs` is misspecified. Make sure that the entries provided are valid n_mhs in `df[!,:nmh]`"
    n_mhs  = sort(unique(n_mhs))

    open(filepath, "w") do fid
        write_smc_statistics_tex_table_headings(fid,
                                                standalone_tex_document = standalone_tex_document,
                                                alphas = alphas)

        for n_mh in n_mhs
            # Subset df to only include rows pertaining to n_mh
            # and remove the nmh column, since the subsetted df now only has
            # entries from a single n_mh
            df_nmh = df[df[!,:nmh] .== n_mh, :]
            df_nmh = df_nmh[:,Base.filter(x -> x != :nmh, names(df_nmh))]

            if length(n_mh) > 1
                @printf fid "\\textbf{\$N_{MH}="
                @printf fid "%i" n_mh
                @printf fid "\$ } \\\\ \\hline "
            end

            write_smc_statistics_tex_table(fid, df_nmh, alphas = alphas, stats = stats)

            @printf fid "\\hline \n"
        end

        @printf fid "\\end{tabular}"
        if standalone_tex_document
            @printf fid "\n\\end{document}"
        end
    end
    println("Wrote $filepath")
end

# Inner method to be called when there ARE time-tempering results
function write_smc_statistics_tex_table(fid, df1::DataFrame, df2::DataFrame;
                                        alphas::Vector{Float64} = [0.0, 0.97, 0.98],
                                        stats::Vector{Symbol} = [:mean_logmdd, :std_logmdd,
                                                                 :mean_min, :mean_schedlength,
                                                                 :mean_resamples],
                                        tempers::Vector{Symbol} = [:plus, :whole])
    temper_name_map = Dict{Symbol, String}(:plus => "DT", :whole => "Full")

    # Grab the column indices of df1 associated to the entries provided in stats
    all_column_headers = keys(getfield(df1, :colindex))
    stats_indices  = [findfirst(x -> x == stat, all_column_headers) for stat in stats]
    @assert !any(map(x -> isequal(x, nothing), stats_indices)) "Keyword argument `stats` is misspecified. Make sure that the entries provided are column names in `df_both`"

    # Grab the row indices of df1 associated to the entries provided in alphas
    @assert issubset(alphas, df1[!,:alpha]) "Keyword argument `alphas` is misspecified. Make sure that the entries provided are valid alphas in `df_both[:alpha]`"
    alpha_indices  = [findfirst(x -> x == alpha, df1[!,:alpha]) for alpha in alphas]

    # Get the tex names of the entries provided in stats
    stats_texnames  = df_columns_to_tex_names(df1, stats)
    n_alphas        = length(alphas)
    n_stats         = length(stats)

    for i in 1:n_stats
        @printf fid "%s" stats_texnames[i]

        # For each tempering type (given by a single dataframe)
        for (temper, df) in zip(tempers, [df1, df2])
            @printf fid "&"
            @printf fid "%s" temper_name_map[temper]

            for j in 1:n_alphas
                @printf fid "&"
                @printf fid "%0.2f" df[alpha_indices[j], stats_indices[i]]
            end
            @printf fid "\\\\ \n"
        end
    end
end

# Inner method to be called when there ARE NO time-tempering results
function write_smc_statistics_tex_table(fid, df::DataFrame;
                                        alphas::Vector{Float64} = [0.0, 0.97, 0.98],
                                        stats::Vector{Symbol} = [:mean_logmdd, :std_logmdd,
                                                                 :mean_min, :mean_schedlength,
                                                                 :mean_resamples])

    # Grab the column indices of df associated to the entries provided in stats
    all_column_headers = keys(getfield(df, :colindex))
    stats_indices  = [findfirst(x -> x == stat, all_column_headers) for stat in stats]
    @assert !any(map(x -> isequal(x, nothing), stats_indices)) "Keyword argument `stats` is misspecified. Make sure that the entries provided are column names in `df`"
    # Grab the row indices of df associated to the entries provided in alphas
    @assert issubset(alphas, sort(unique(df[!,:alpha]))) "Keyword argument `alphas` is misspecified. Make sure that the entries provided are valid alphas in `df[!,:alpha]`"
    alpha_indices  = [findfirst(x -> x == alpha, df[!,:alpha]) for alpha in alphas]

    # Get the tex names of the entries provided in stats
    stats_texnames  = df_columns_to_tex_names(df, stats)
    n_stats         = length(stats)
    n_alphas        = length(alphas)

    for i in 1:n_stats
        @printf fid "%s" stats_texnames[i]
        for j in 1:n_alphas
            @printf fid "&"
            @printf fid "%0.2f" df[alpha_indices[j], stats_indices[i]]
        end
        @printf fid "\\\\ \n"
    end
end

# For writing out the column headers for both time-tempering and non-time-tempering results
function write_smc_statistics_tex_table_headings(fid; standalone_tex_document::Bool = false,
                                                 alphas::Vector{Float64} = [0.0, 0.97, 0.98],
                                                 tempers::Vector{Symbol} = [:whole])

    n_alphas = length(alphas)

    if standalone_tex_document
        @printf fid "\\documentclass{article}\n\n"
        @printf fid "\\begin{document}\n\n"
    end

    if length(tempers) > 1
        number_of_left_aligns = 2
    else
        number_of_left_aligns = 1
    end

    # Write the number of columns there will be
    @printf fid "\\begin{tabular} {"
        for i = 1:(n_alphas + 2)
            if i <= number_of_left_aligns
                # Left-aligned
                @printf fid "l"
            else
                # Right-aligned
                @printf fid "r"
            end
        end
    @printf fid "} "

    @printf fid "\n \\hline \\hline \n"

    # Empty header above statistics
    @printf fid "&"

    # Empty header above tempering type column
    if length(tempers) > 1
        @printf fid "&"
    end

    # Write the alpha column header
    for k = 1:n_alphas
        alpha = alphas[k]

        if k != 1
            @printf fid "&"
        end
        if alpha == 0.0
            @printf fid "Fixed"
        else
            @printf fid "\$\\alpha = \$"
            @printf fid "%0.2f" alpha
        end
    end
    @printf fid "\\\\ \n \\hline \n"
end

# Helper method for choosing the tex column headers
# from the dataframe.
function df_columns_to_tex_names(df::DataFrame, column_names::Vector{Symbol})
    @assert issubset(column_names, keys(getfield(df, :colindex))) "column_names must be a subset of the column names of df"

    # Modify this to add more tex names if needed
    column_map = Dict{Symbol, String}(:mean_logmdd      => "Mean log(MDD)",
                                      :std_logmdd       => "StdD log(MDD)",
                                      :mean_min         => "Runtime [Min]",
                                      :mean_schedlength => "Schedule Length",
                                      :mean_resamples   => "Resamples")

    column_tex_strings = Vector{String}(undef, length(column_names))
    for (i, col_name) in enumerate(column_names)
        column_tex_strings[i] = column_map[col_name]
    end

    return column_tex_strings
end
