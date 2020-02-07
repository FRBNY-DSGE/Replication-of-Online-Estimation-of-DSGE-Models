using DataStructures

# Herbst/Schorfheide's posterior values
function hs_smc_posterior_values()
    hs_dict = OrderedDict{Symbol, Tuple{Float64, Float64}}()
    hs_dict[:φ]     = (5.70, 0.03)
    hs_dict[:σ_c]   = (1.33, 0.00)
    hs_dict[:h]     = (0.72, 0.00)
    hs_dict[:ξ_w]   = (0.70, 0.00)
    hs_dict[:σ_l]   = (1.87, 0.02)
    hs_dict[:ξ_p]   = (0.64, 0.00)
    hs_dict[:ι_w]   = (0.57, 0.00)
    hs_dict[:ι_p]   = (0.25, 0.00)
    hs_dict[:ψ]     = (0.55, 0.00)
    hs_dict[:Φ]     = (1.58, 0.00)
    hs_dict[:r_π]   = (2.05, 0.01)
    hs_dict[:ρ]     = (0.80, 0.00)
    hs_dict[:r_y]   = (0.09, 0.00)
    hs_dict[:r_Δy]  = (0.22, 0.00)
    hs_dict[:π]     = (0.69, 0.00)
    hs_dict[:β]     = (0.17, 0.00)
    hs_dict[:l]     = (0.72, 0.02)
    hs_dict[:γ]     = (0.42, 0.00)
    hs_dict[:α]     = (0.19, 0.00)

    hs_dict[:ρ_a]   = (0.96, 0.00)
    hs_dict[:ρ_b]   = (0.21, 0.00)
    hs_dict[:ρ_g]   = (0.98, 0.00)
    hs_dict[:ρ_i]   = (0.73, 0.00)
    hs_dict[:ρ_r]   = (0.15, 0.00)
    hs_dict[:ρ_p]   = (0.90, 0.00)
    hs_dict[:ρ_w]   = (0.97, 0.00)

    hs_dict[:μ_p]   = (0.69, 0.00)
    hs_dict[:μ_w]   = (0.85, 0.00)

    hs_dict[:ρ_ga]  = (0.50, 0.00)

    hs_dict[:σ_a]   = (0.47, 0.00)
    hs_dict[:σ_b]   = (0.24, 0.00)
    hs_dict[:σ_g]   = (0.54, 0.00)
    hs_dict[:σ_i]   = (0.45, 0.00)
    hs_dict[:σ_r]   = (0.25, 0.00)
    hs_dict[:σ_p]   = (0.14, 0.00)
    hs_dict[:σ_w]   = (0.25, 0.00)
    return hs_dict
end

function hs_smc_posterior_bands()
    hs_dict = OrderedDict{Symbol, Tuple{Float64, Float64}}()
    hs_dict[:φ]     = (4.12, 7.45)
    hs_dict[:σ_c]   = (1.13, 1.54)
    hs_dict[:h]     = (0.65, 0.79)
    hs_dict[:ξ_w]   = (0.59, 0.80)
    hs_dict[:σ_l]   = (1.01, 2.84)
    hs_dict[:ξ_p]   = (0.54, 0.73)
    hs_dict[:ι_w]   = (0.36, 0.77)
    hs_dict[:ι_p]   = (0.12, 0.41)
    hs_dict[:ψ]     = (0.37, 0.74)
    hs_dict[:Φ]     = (1.46, 1.71)
    hs_dict[:r_π]   = (1.77, 2.34)
    hs_dict[:ρ]     = (0.76, 0.84)
    hs_dict[:r_y]   = (0.05, 0.12)
    hs_dict[:r_Δy]  = (0.18, 0.27)
    hs_dict[:π]     = (0.52, 0.87)
    hs_dict[:β]     = (0.08, 0.27)
    hs_dict[:l]     = (-1.21,2.65)
    hs_dict[:γ]     = (0.39, 0.45)
    hs_dict[:α]     = (0.16, 0.22)

    hs_dict[:ρ_a]   = (0.94, 0.98)
    hs_dict[:ρ_b]   = (0.08, 0.37)
    hs_dict[:ρ_g]   = (0.96, 0.99)
    hs_dict[:ρ_i]   = (0.63, 0.82)
    hs_dict[:ρ_r]   = (0.06, 0.27)
    hs_dict[:ρ_p]   = (0.80, 0.97)
    hs_dict[:ρ_w]   = (0.95, 0.99)

    hs_dict[:μ_p]   = (0.50, 0.84)
    hs_dict[:μ_w]   = (0.73, 0.93)

    hs_dict[:ρ_ga]  = (0.35, 0.65)

    hs_dict[:σ_a]   = (0.42, 0.52)
    hs_dict[:σ_b]   = (0.20, 0.28)
    hs_dict[:σ_g]   = (0.49, 0.59)
    hs_dict[:σ_i]   = (0.38, 0.54)
    hs_dict[:σ_r]   = (0.22, 0.28)
    hs_dict[:σ_p]   = (0.11, 0.17)
    hs_dict[:σ_w]   = (0.21, 0.29)
    return hs_dict
end

function hs_mh_posterior_values()
    hs_dict = OrderedDict{Symbol, Tuple{Float64, Float64}}()
    hs_dict[:φ]     = (5.70, 0.03)
    hs_dict[:σ_c]   = (1.33, 0.00)
    hs_dict[:h]     = (0.72, 0.00)
    hs_dict[:ξ_w]   = (0.70, 0.00)
    hs_dict[:σ_l]   = (1.90, 0.02)
    hs_dict[:ξ_p]   = (0.65, 0.00)
    hs_dict[:ι_w]   = (0.57, 0.00)
    hs_dict[:ι_p]   = (0.26, 0.00)
    hs_dict[:ψ]     = (0.55, 0.00)
    hs_dict[:Φ]     = (1.58, 0.00)
    hs_dict[:r_π]   = (2.04, 0.01)
    hs_dict[:ρ]     = (0.81, 0.00)
    hs_dict[:r_y]   = (0.09, 0.00)
    hs_dict[:r_Δy]  = (0.23, 0.00)
    hs_dict[:π]     = (0.69, 0.00)
    hs_dict[:β]     = (0.17, 0.00)
    hs_dict[:l]     = (0.70, 0.02)
    hs_dict[:γ]     = (0.42, 0.00)
    hs_dict[:α]     = (0.19, 0.00)

    hs_dict[:ρ_a]   = (0.96, 0.00)
    hs_dict[:ρ_b]   = (0.22, 0.00)
    hs_dict[:ρ_g]   = (0.98, 0.00)
    hs_dict[:ρ_i]   = (0.73, 0.00)
    hs_dict[:ρ_r]   = (0.15, 0.00)
    hs_dict[:ρ_p]   = (0.89, 0.00)
    hs_dict[:ρ_w]   = (0.97, 0.00)

    hs_dict[:μ_p]   = (0.72, 0.00)
    hs_dict[:μ_w]   = (0.85, 0.00)

    hs_dict[:ρ_ga]  = (0.50, 0.00)

    hs_dict[:σ_a]   = (0.47, 0.00)
    hs_dict[:σ_b]   = (0.24, 0.00)
    hs_dict[:σ_g]   = (0.54, 0.00)
    hs_dict[:σ_i]   = (0.45, 0.00)
    hs_dict[:σ_r]   = (0.25, 0.00)
    hs_dict[:σ_p]   = (0.15, 0.00)
    hs_dict[:σ_w]   = (0.25, 0.00)
    return hs_dict
end

function hs_mh_posterior_bands()
    hs_dict = OrderedDict{Symbol, Tuple{Float64, Float64}}()
    hs_dict[:φ]     = (4.11, 7.48)
    hs_dict[:σ_c]   = (1.14, 1.55)
    hs_dict[:h]     = (0.65, 0.79)
    hs_dict[:ξ_w]   = (0.59, 0.80)
    hs_dict[:σ_l]   = (1.05, 2.88)
    hs_dict[:ξ_p]   = (0.56, 0.74)
    hs_dict[:ι_w]   = (0.35, 0.77)
    hs_dict[:ι_p]   = (0.13, 0.42)
    hs_dict[:ψ]     = (0.37, 0.73)
    hs_dict[:Φ]     = (1.46, 1.71)
    hs_dict[:r_π]   = (1.76, 2.34)
    hs_dict[:ρ]     = (0.76, 0.85)
    hs_dict[:r_y]   = (0.05, 0.13)
    hs_dict[:r_Δy]  = (0.18, 0.27)
    hs_dict[:π]     = (0.52, 0.87)
    hs_dict[:β]     = (0.08, 0.27)
    hs_dict[:l]     = (-1.23, 2.62)
    hs_dict[:γ]     = (0.39, 0.45)
    hs_dict[:α]     = (0.16, 0.22)

    hs_dict[:ρ_a]   = (0.94, 0.97)
    hs_dict[:ρ_b]   = (0.08, 0.38)
    hs_dict[:ρ_g]   = (0.96, 0.99)
    hs_dict[:ρ_i]   = (0.63, 0.82)
    hs_dict[:ρ_r]   = (0.05, 0.26)
    hs_dict[:ρ_p]   = (0.80, 0.96)
    hs_dict[:ρ_w]   = (0.95, 0.99)

    hs_dict[:μ_p]   = (0.54, 0.85)
    hs_dict[:μ_w]   = (0.74, 0.93)

    hs_dict[:ρ_ga]  = (0.35, 0.65)

    hs_dict[:σ_a]   = (0.42, 0.52)
    hs_dict[:σ_b]   = (0.20, 0.28)
    hs_dict[:σ_g]   = (0.49, 0.59)
    hs_dict[:σ_i]   = (0.38, 0.54)
    hs_dict[:σ_r]   = (0.22, 0.28)
    hs_dict[:σ_p]   = (0.12, 0.18)
    hs_dict[:σ_w]   = (0.21, 0.28)
    return hs_dict
end

function hs_param_mappings()
    hs_map = OrderedDict{Symbol, Symbol}()
    hs_map[:S′′]    = :φ
    hs_map[:σ_c]    = :σ_c
    hs_map[:h]      = :h
    hs_map[:ζ_w]    = :ξ_w
    hs_map[:ν_l]    = :σ_l
    hs_map[:ζ_p]    = :ξ_p
    hs_map[:ι_w]    = :ι_w
    hs_map[:ι_p]    = :ι_p
    hs_map[:ppsi]   = :ψ
    hs_map[:Φ]      = :Φ
    hs_map[:ψ1]    = :r_π
    hs_map[:ρ]      = :ρ
    hs_map[:ψ2]    = :r_y
    hs_map[:ψ3]    = :r_Δy
    hs_map[:π_star] = :π
    hs_map[:Lmean]  = :l
    hs_map[:β]      = :β
    hs_map[:γ]      = :γ
    hs_map[:α]      = :α

    hs_map[:ρ_z]    = :ρ_a
    hs_map[:ρ_b]    = :ρ_b
    hs_map[:ρ_g]    = :ρ_g
    hs_map[:ρ_μ]    = :ρ_i
    hs_map[:ρ_rm]   = :ρ_r
    hs_map[:ρ_λ_f]  = :ρ_p
    hs_map[:ρ_λ_w]  = :ρ_w

    hs_map[:η_λ_f]  = :μ_p
    hs_map[:η_λ_w]  = :μ_w
    hs_map[:η_gz]   = :ρ_ga

    hs_map[:σ_z]    = :σ_a
    hs_map[:σ_b]    = :σ_b
    hs_map[:σ_g]    = :σ_g
    hs_map[:σ_μ]    = :σ_i
    hs_map[:σ_rm]   = :σ_r
    hs_map[:σ_λ_f]  = :σ_p
    hs_map[:σ_λ_w]  = :σ_w

    return hs_map
end
