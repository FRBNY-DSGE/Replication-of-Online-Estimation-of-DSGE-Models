function data_spec_and_cond_type_to_filestring(data_spec::Int, cond_type::Symbol)
    if data_spec == 4 && cond_type == :full
        filestring_ext = "both"
    elseif data_spec == 1 && cond_type == :full
        filestring_ext = "nowcast"
    elseif data_spec == 4 && cond_type == :semi
        filestring_ext = "bluechip"
    elseif data_spec == 1 && cond_type == :semi
        filestring_ext = "neither"
    else
        throw("Invalid data_spec/cond_type combo. Something's wrong")
    end

    return filestring_ext
end

function predicted_variables_to_filestring(predicted_variables::Vector{Symbol})
    if predicted_variables == [:obs_gdp]
        pred_var_string = "gdp"
    elseif predicted_variables == [:obs_gdpdeflator]
        pred_var_string = "def"
    else
        pred_var_string = "both"
    end

    return pred_var_string
end

