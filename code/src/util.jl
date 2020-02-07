# Determines the vintage associated to a given forecast year and quarter.
# Currently following the convention from the Realtime forecasting exercise
# of taking Q1 through Q4 to be: April 10, July 10, Oct 10, and Jan 10 (of the following year)
function forecast_vintage(forecast_year::Int, forecast_quarter::Int)
    if forecast_quarter == 4
        forecast_year += 1
    end
    year = string(forecast_year)[3:4]

    month_date =
    if forecast_quarter == 1
        "0410"
    elseif forecast_quarter == 2
        "0710"
    elseif forecast_quarter ==3
        "1010"
    elseif forecast_quarter == 4
        "0110"
    else
        throw("Invalid forecast_quarter. Must be in 1:4")
    end
    return string(year, month_date)
end

function forecast_vintage(d::Date)
    forecast_vintage(Dates.year(d), Dates.quarterofyear(d))
end

# Assumes df has a :date column that contains date indices
# If the T passed in is the date of the first forecast quarter
# then
"""
```
function subset_df(df, T; end_date, T_forecast_quarter)
```

Assumes the df has a :date column that contains date indices.

### Arguments
- `df::DataFrame`
- `T::Date`

### Keyword Arguments
- `end_date::Bool`: Whether T is the end date of the dataframe (as opposed to the start date)
- `forecast_date::Bool`: If the T passed in is the date of the first forecast quarter, then offset the T index by one to account for it.

"""
function subset_df(df::DataFrame, T::Date;
                   end_date::Bool = true,
                   forecast_date::Bool = false)
    forecast_date && (T = iterate_quarters(T, -1))
    T_index = findfirst(x -> x == T, df[:date])

    if end_date
        return df[1:T_index, :]
    else
        return df[T_index:end, :]
    end
end

# For subsetting the DataFrame constructed from the master reference,
# that maps temper_type to a DataFrame of statistics for that temper_type,
# by a particular column name and value.
function subset_df(df::DataFrame, col_name::Symbol, col_value;
                   returned_columns = names(df))
    # It would be nice to figure out how to do this in Query.jl
    # but I can't figure out how to programmatically include
    # a generic "col_name" in a query. May require meta-programming.

    df_return = df[findall(df[col_name] .== col_value), :]
    return df_return[:, findall((in)(names(df)), returned_columns)]
end
