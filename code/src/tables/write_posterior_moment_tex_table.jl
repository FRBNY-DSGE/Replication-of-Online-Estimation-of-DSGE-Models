function write_posterior_moment_tex_table(m::AbstractModel, clouds::Dict{Float64, Vector{ParticleCloud}},
                                          tempering_target; compare_hs::Bool = false,
                                          plotroot = tablespath(m, "estimate"))
    filepath = plotroot*"/posterior_moments_adpt=$tempering_target.tex"
    write_posterior_moment_tex_table(m, clouds[tempering_target], compare_hs = compare_hs, filepath = filepath)
end

function write_posterior_moment_tex_table(m::AbstractModel, clouds::Array{ParticleCloud};
                                          compare_hs::Bool = false, filepath::String = tablespath(m, "estimate")*"/posterior_moments.tex")
    df1 = load_posterior_moments(m, clouds)

    reformat_posterior_moments_table_column_headers!(df1)

    if compare_hs
        formatted_columns = "|c|cccc|cccc|"
        vals = hs_smc_posterior_values()
        bands = hs_smc_posterior_bands()
        hs_map = hs_param_mappings()
        free_parameters = Base.filter(x -> x.fixed==false, m.parameters)
        hs_smc_post_mean = Vector(length(free_parameters))
        hs_smc_post_std = Vector(length(free_parameters))
        hs_smc_post_lb = Vector(length(free_parameters))
        hs_smc_post_ub = Vector(length(free_parameters))
        for i in 1:length(free_parameters)
            hs_smc_post_mean[i] = vals[hs_map[free_parameters[i].key]][1]
            hs_smc_post_std[i] = vals[hs_map[free_parameters[i].key]][2]
            hs_smc_post_lb[i] = bands[hs_map[free_parameters[i].key]][1]
            hs_smc_post_ub[i] = bands[hs_map[free_parameters[i].key]][2]
        end

        df2 = DataFrame(post_mean = hs_smc_post_mean,
                        post_std = hs_smc_post_std,
                        post_lb = hs_smc_post_lb,
                        post_ub = hs_smc_post_ub)

        names!(df2, [Symbol("\$\\bar\\{\\theta\\}\$"), Symbol("std\$(\\bar\\{\\theta\\})\$"),
                Symbol("5\\% LB"), Symbol("95\\% UB")])

        df_to_tex(filepath, df1, df2, "FRBNY", "HS", formatted_columns = formatted_columns, enclose_table = true)
    else
        formatted_columns = "|c|cccc|"
        df_to_tex(filepath, df1, formatted_columns = formatted_columns, enclose_table = true)
    end
end


function write_posterior_moment_tex_table(m::AbstractModel, clouds::Vector{Vector{ParticleCloud}};
                                          filepath::String = tablespath(m, "estimate")*"/posterior_moments.tex")
    dfs = Vector{DataFrame}(length(clouds))
    for i=1:length(dfs)
        dfs[i] = load_posterior_moments(m, clouds[i])
        reformat_posterior_moments_table_column_headers!(dfs[i])
    end

    formatted_columns = "|c|cccc|cccc|cccc|"
    dfs[2] = dfs[2][Base.filter(x -> x != :param, names(dfs[2]))]
    dfs[3] = dfs[3][Base.filter(x -> x != :param, names(dfs[3]))]

    df_to_tex(filepath, dfs[1], dfs[2], dfs[3], "Fixed", "Adaptive .97", "Adaptive .98", formatted_columns = formatted_columns, enclose_table = true)
  #  else
 #       formatted_columns = "|c|cccc|"
  #      df_to_tex(filepath, df1, formatted_columns = formatted_columns, enclose_table = true)
  #  end
end


# Method to be used with load_posterior_moments
# to rename columns according to agreed upon style guidelines
function reformat_posterior_moments_table_column_headers!(df::DataFrame)
    @assert names(df) == [:param, :post_mean, :post_std, :post_lb, :post_ub] "Must be a DataFrame created by load_posterior_moments."
    names!(df, [:param, Symbol("\$\\bar\\{\\theta\\}\$"), Symbol("std\$(\\bar\\{\\theta\\})\$"),
                Symbol("5\\% LB"), Symbol("95\\% UB")])
end
