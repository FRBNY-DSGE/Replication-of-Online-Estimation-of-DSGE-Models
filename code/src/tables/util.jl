escape_tex(s::String) = replace(s, "_", "\\_")               # For preserving sub-scripts
escape_tex(s::Symbol) = Symbol(escape_tex(string(s)))
double_escape_tex(s::String) = replace(s, "_", "\\_")       # For preserving under-scores
double_escape_tex(s::Symbol) = Symbol(double_escape_tex(string(s)))

# standalone_tex_document for quick view of table
# formatted_columns allows you to override the standard "cccc" column format
# to input your own custom format
# enclosed_table determines whether the table has boundaries
function df_to_tex(filename::String, df::DataFrame;
                   standalone_tex_document::Bool = false,
                   formatted_columns::String = "",
                   enclose_table::Bool = false)

    nrows, ncols = size(df)
    coltypes = map(colname -> eltype(df[colname]), names(df))

    open(filename, "w") do fid

        if standalone_tex_document
            @printf fid "\\documentclass{article}\n\n"
            @printf fid "\\begin{document}\n\n"
        end

        # Begin table
        @printf fid "\\begin{tabular}{"
        if isempty(formatted_columns)
            for i = 1:ncols
                if enclose_table && i == 1
                    @printf fid "|c"
                elseif enclose_table && i == ncols
                    @printf fid "c|"
                else
                    @printf fid "c"
                end
            end
        else
            @assert count(t -> t == 'c', collect(formatted_columns)) == ncols "Incorrect number of columns specified by formatted_columns"
            @printf fid "%s" formatted_columns
        end
        @printf fid "}\n"

        if enclose_table
            @printf fid "\n\\hline\n"
        end

        # Header
        for (j, colname) in enumerate(names(df))
            if j != 1
                @printf fid " & "
            end
            @printf fid "%s" double_escape_tex(DSGE.detexify(colname))
        end
        @printf fid " \\\\ \\hline\n"

        # Body
        for i in 1:nrows
            for j in 1:ncols
                if j != 1
                    @printf fid " & "
                end
                if coltypes[j] in [String, Symbol]
                    @printf fid "\$%s\$" escape_tex(DSGE.detexify(df[i, j]))
                else
                    @printf fid "%0.3f" df[i, j]
                end
            end
            @printf fid " \\\\\n"
        end

        if enclose_table
            @printf fid "\\hline\n"
        end

        # End table
        @printf fid "\\end{tabular}\n"

        if standalone_tex_document
            @printf fid "\n\\end{document}"
        end
    end

    println("Wrote $filename")
end


function df_to_tex(filename::String, df1::DataFrame, df2::DataFrame, multicolumn1::String, multicolumn2::String;
                   standalone_tex_document::Bool = false,
                   formatted_columns::String = "",
                   enclose_table::Bool = false)

    nrows, ncols = size(df1)
    coltypes1 = map(colname -> eltype(df1[colname]), names(df1))
    coltypes2 = map(colname -> eltype(df2[colname]), names(df2))
    coltypes = vcat(coltypes1, coltypes2)

    open(filename, "w") do fid

        if standalone_tex_document
            @printf fid "\\documentclass{article}\n\n"
            @printf fid "\\begin{document}\n\n"
        end

        # Begin table
        @printf fid "\\begin{tabular}{"
        if isempty(formatted_columns)
            for i = 1:ncols
                if enclose_table && i == 1
                    @printf fid "|c"
                elseif enclose_table && i == ncols
                    @printf fid "c|"
                else
                    @printf fid "c"
                end
            end
        else
            @show size(df1, 2) + size(df2, 2)
            @assert count(t -> t == 'c', collect(formatted_columns)) == size(df1,2) + size(df2, 2) "Incorrect number of columns specified by formatted_columns"
            @printf fid "%s" formatted_columns
        end
        @printf fid "}\n"

        if enclose_table
            @printf fid "\n\\hline\n"
        end

        @printf fid "& \\multicolumn{4}{c}{"
        @printf fid "%s" multicolumn1
        @printf fid "} & \\multicolumn{4}{c}{"
        @printf fid "%s" multicolumn2
        @printf fid "} \\\\ \n"

        # Header
        for (j, colname) in enumerate(vcat(names(df1), names(df2)))
            if j != 1
                @printf fid " & "
            end
            @printf fid "%s" double_escape_tex(DSGE.detexify(colname))
        end
        @printf fid " \\\\ \\hline\n"

        # Body
        for i in 1:nrows
            l = 1
            for df in [df1, df2]
                @show df
                for j in 1:size(df, 2)
                    if l != 1
                        @printf fid " & "
                    end
                    if coltypes[l] in [String, Symbol]
                        @printf fid "\$%s\$" escape_tex(DSGE.detexify(df[i, j]))
                    else
                        @printf fid "%0.3f" df[i, j]
                    end
                    l = l + 1
                end
            end
            @printf fid " \\\\\n"
        end

        if enclose_table
            @printf fid "\\hline\n"
        end

        # End table
        @printf fid "\\end{tabular}\n"

        if standalone_tex_document
            @printf fid "\n\\end{document}"
        end
    end

    println("Wrote $filename")
end


function df_to_tex(filename::String, df1::DataFrame, df2::DataFrame, df3::DataFrame, multicolumn1::String, multicolumn2::String, multicolumn3::String;
                   standalone_tex_document::Bool = false,
                   formatted_columns::String = "",
                   enclose_table::Bool = false)

    nrows, ncols = size(df1)
    coltypes1 = map(colname -> eltype(df1[colname]), names(df1))
    coltypes2 = map(colname -> eltype(df2[colname]), names(df2))
    coltypes3 = map(colname -> eltype(df3[colname]), names(df3))
    coltypes = vcat(coltypes1, coltypes2, coltypes3)

    open(filename, "w") do fid

        if standalone_tex_document
            @printf fid "\\documentclass{article}\n\n"
            @printf fid "\\begin{document}\n\n"
        end

        # Begin table
        @printf fid "\\begin{tabular}{"
        if isempty(formatted_columns)
            for i = 1:ncols
                if enclose_table && i == 1
                    @printf fid "|c"
                elseif enclose_table && i == ncols
                    @printf fid "c|"
                else
                    @printf fid "c"
                end
            end
        else
            @assert count(t -> t == 'c', collect(formatted_columns)) == size(df1,2) + size(df2, 2) + size(df3, 2)  "Incorrect number of columns specified by formatted_columns"
            @printf fid "%s" formatted_columns
        end
        @printf fid "}\n"

        if enclose_table
            @printf fid "\n\\hline\n"
        end

        @printf fid "& \\multicolumn{4}{c}{"
        @printf fid "%s" multicolumn1
        @printf fid "} & \\multicolumn{4}{c}{"
        @printf fid "%s" multicolumn2
        @printf fid "} & \\multicolumn{4}{c}{"
        @printf fid "%s" multicolumn3
        @printf fid "} \\\\ \n"

        # Header
        for (j, colname) in enumerate(vcat(names(df1), names(df2), names(df3)))
            if j != 1
                @printf fid " & "
            end
            @printf fid "%s" double_escape_tex(DSGE.detexify(colname))
        end
        @printf fid " \\\\ \\hline\n"

        # Body
        for i in 1:nrows
            l = 1
            for df in [df1, df2, df3]
                for j in 1:size(df, 2)
                    if l != 1
                        @printf fid " & "
                    end
                    if coltypes[l] in [String, Symbol]
                        @printf fid "\$%s\$" escape_tex(DSGE.detexify(df[i, j]))
                    else
                        @printf fid "%0.3f" df[i, j]
                    end
                    l = l + 1
                end
            end
            @printf fid " \\\\\n"
        end

        if enclose_table
            @printf fid "\\hline\n"
        end

        # End table
        @printf fid "\\end{tabular}\n"

        if standalone_tex_document
            @printf fid "\n\\end{document}"
        end
    end

    println("Wrote $filename")
end
