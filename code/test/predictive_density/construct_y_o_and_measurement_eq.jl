using DSGE
include("$(SMC_DIR)/code/src/SMCProject.jl")

data_spec = 1
est_spec  = 2

input_type = :full

model = :Model805
subspec = "ss1"
year = 1992
quarter = 1
run_date = "190107"
setting_overrides = Dict{Symbol, DSGE.Setting}(:est_spec => Setting(:est_spec, est_spec, true, "est", "Print the estimation specification in the filestring."))

start_date = DSGE.quartertodate("$year-Q$quarter")
horizon    = 4
i          = 1 # How many data periods ahead of `start_date` we want to load the data

m = prepare_model(model, year, quarter, run_date; subspec = subspec,
                  data_spec = 1, est_spec = 2, setting_overrides = setting_overrides)
params, data, data_o = setup_params_and_data(m, input_type, i, horizon, start_date)

system = compute_system(m)

ant_shock_inds = find_ant_shock_inds(m)
non_ant_shock_inds = setdiff(1:n_observables(m), ant_shock_inds)

F, y_o, D_tilde, Z_tilde = construct_y_o_and_measurement_eq(data_o, system, horizon,
                                                            ant_shock_inds,
                                                            non_ant_shock_inds)

# Testing that the averages are being computed correctly
# y_o, given horizon = 4, are 4 consecutive data observations stacked on top of each other
# 1959-Q3 through 1991-Q4 (the data periods contained in data) are 130 obs in total
# so in this case the pre-sample of 1959-Q3 and -Q4 are being included in the pred density calculation.
# data_o is 4 periods longer.

ind_ranges = [1:size(data, 1), size(data, 1)+1:2*size(data, 1), 2*size(data, 1)+1:3*size(data, 1),
              3*size(data, 1)+1:4*size(data, 1)]

# Check that y_o is stacked properly
t1_ind     = size(data, 2)
@testset "Checking y_o is constructed properly" begin
    for (i, inds) in enumerate(ind_ranges)
        @test y_o[inds] ≈ data_o[:, t1_ind + i]
    end
end

# Check that F*y_o is computing the average correctly
w = StatsBase.Weights(fill(0.25, 4))
@testset "Checking F*y_o average is correct" begin
    @test F*y_o ≈ mean(data_o[:, (t1_ind + 1):(t1_ind + 4)], w, 2)
end

# Check that D_tilde is stacked properly
@testset "Check D_tilde stacking" begin
    D_tilde_first = D_tilde[ind_ranges[1]]
    for inds in ind_ranges[2:end]
        @test D_tilde[inds] ≈ D_tilde_first
    end
end

# Check that Z_tilde is stacked properly
@testset "Check Z_tilde stacking" begin
    n_obs      = n_observables(m)
    n_states_Z = size(system[:ZZ], 2)
    Z_tilde_first = Z_tilde[1:n_obs, 1:n_states_Z]

    for i in 2:horizon
        @test Z_tilde[(i-1)*n_obs+1:i*n_obs, (i-1)*n_states_Z+1:i*n_states_Z] ≈ Z_tilde_first
    end
end
