path = dirname(@__FILE__)

file = jldopen("$path/../reference/forecast_states.jld2", "r")
s_all = read(file, "s_all")
P_all = read(file, "P_all")
s_t1_t1 = read(file, "s_t1_t1")
P_t1_t1 = read(file, "P_t1_t1")
system = read(file, "system")
close(file)

n_states = length(s_all[1])
T = system[:TTT]
R = system[:RRR]
Q = system[:QQ]

@testset "Checking s_all construction is correct" begin
# Manually go by each block and check that things are correct
    for (i, s) in enumerate(s_all)
        @test s ≈ T^i*s_t1_t1
    end
end

@testset "Checking P_all construction is correct" begin
    P_old = P_t1_t1
    for (i, P) in enumerate(P_all)
        P_new = T*P_old*T'+R*Q*R'
        @test P_all[i] ≈ P_new
        P_old = P_new
    end
end

nothing
