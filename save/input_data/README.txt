smc.h5 is the AnSchorfheide dataset that goes from 1960-Q1 through 2017-Q3, created by
Abhi/Pearl when they initially refactored the code that I (Michael) wrote as an intern. It
is possible to trace the origin of this file by looking at Github.

sw_orig_smc.h5 is the SmetsWoutersOrig dataset that goes from 1965-Q4 through 2014-Q4
(where 1965-Q4 through 1966-Q3 is treated as the pre-sample) and was created by Ethan when
we created SMC Documentation. The way to create it is documented by sw_data_loading.jl

as_data.jld and sw_data.jld are both of these datasets as DataFrames (reconstructed from
the matrices with the correct date column indices) to interface properly with the driver
files.
