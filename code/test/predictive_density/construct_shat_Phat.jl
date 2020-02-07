path = dirname(@__FILE__)

# Output generated with horizon = 4
file = jldopen("$path/../reference/construct_shat_Phat.jld2", "r")
s_all = read(file, "s_all")
P_all = read(file, "P_all")
s_t1_t1 = read(file, "s_t1_t1")
P_t1_t1 = read(file, "P_t1_t1")
system = read(file, "system")
close(file)

horizon = 4
n_states = length(s_all[1])
T = system[:TTT]
R = system[:RRR]
Q = system[:QQ]

s_hat, P_hat = construct_shat_Phat(s_all, P_all, system)

start_inds = collect(1:n_states:length(s_hat))
end_inds   = collect(n_states:n_states:length(s_hat))
inds = Array{UnitRange{Int64}}(undef, length(start_inds))

for (i, st, en) in zip(1:length(start_inds), start_inds, end_inds)
    inds[i] = st:en
end

@testset "Checking s_hat construction is correct" begin
    # Check s_hat
    for (i, ind) in enumerate(inds)
        @test s_hat[ind] ≈ T^i*s_t1_t1
    end
end

@testset "Checking P_hat construction is correct" begin
    # Check P_hat
    # First column, P_t|t-1
    @test P_hat[inds[1], inds[1]] ≈ P_all[1]
    @test P_hat[inds[2], inds[1]] ≈ T*P_all[1]
    @test P_hat[inds[3], inds[1]] ≈ T^2*P_all[1]
    @test P_hat[inds[4], inds[1]] ≈ T^3*P_all[1]

    # First row, P_t|t-1
    @test P_hat[inds[1], inds[2]] ≈ P_all[1]*T'
    @test P_hat[inds[1], inds[3]] ≈ P_all[1]*(T^2)'
    @test P_hat[inds[1], inds[4]] ≈ P_all[1]*(T^3)'

    # Second column, P_t+1|t-1
    @test P_hat[inds[2], inds[2]] ≈ P_all[2]
    @test P_hat[inds[3], inds[2]] ≈ T*P_all[2]
    @test P_hat[inds[4], inds[2]] ≈ T^2*P_all[2]

    # Second row, P_t+1|t-1
    @test P_hat[inds[2], inds[3]] ≈ P_all[2]*T'
    @test P_hat[inds[2], inds[4]] ≈ P_all[2]*(T^2)'

    # Third column, P_t+2|t-1
    @test P_hat[inds[3], inds[3]] ≈ P_all[3]
    @test P_hat[inds[4], inds[3]] ≈ T*P_all[3]

    # Third row, P_t+2|t-1
    @test P_hat[inds[3], inds[4]] ≈ P_all[3]*T'

    # Fourth column/row, P_t+3|t-1
    @test P_hat[inds[4], inds[4]] ≈ P_all[4]
end

nothing
