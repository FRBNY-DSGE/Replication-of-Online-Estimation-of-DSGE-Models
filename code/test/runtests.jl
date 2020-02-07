global DIR = DSGEJL
using Test
@everywhere using DSGE, JLD2
@everywhere include("$(SMC_DIR)/code/src/SMCProject.jl")

my_tests = [
            "predictive_density/forecast_states",
            "predictive_density/construct_shat_Phat",
            # Need to fix the way the SMCProject code handles paths for MH and SMC
            # since their filestring_bases and absolute directory paths are different.
            # "predictive_density/test_kalman"
           # "predictive_density/construct_y_o_and_measurement_eq"
            ]

for test in my_tests
    test_file = string("$test.jl")
    @printf " * %s\n" test_file
    include(test_file)
end
