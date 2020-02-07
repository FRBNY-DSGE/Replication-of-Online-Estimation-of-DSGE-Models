# This will serve as a temporary "module"
# until we decide to build a more structured
# codebase for the SMC predictive density project.

# Loading in the realtime codebase (smc_integration-0.7 branch)
include("RealtimeData/src/RealtimeData.jl")

#const SMC_DIR = "$DIR/smc/nyfed_dsge/SMCProject"
const REALTIME_FORECAST_HORIZONS = 16

using Dates, Printf, Test
using DSGE, DSGEModels
using HDF5, JLD2, FileIO
using DataFrames, CSV, Query
using ClusterManagers
using OrderedCollections
using Statistics, StatsBase
using SparseArrays
using LinearAlgebra
using KernelDensity
using SMC

#using Iterators
#using Gadfly, Immerse # Issues running parallel jobs while loading these packages
using Plots, Measures
gr()

import DSGE: VERBOSITY, Setting, quartertodate, quarter_range, quarter_date_to_number

include("util.jl")
include("helpers.jl")
include("io.jl")
include("settings/model_settings.jl")
include("settings/settings.jl")
include("drivers.jl")
include("file_management.jl")
include("realtime_wrappers.jl")
include("predictive_density/io.jl")
include("predictive_density/predictive_density.jl")
include("predictive_density/helpers.jl")
include("predictive_density/util.jl")
include("tables/write_posterior_moment_tex_table.jl")
include("tables/write_smc_statistics_tex_table.jl")
include("tables/save_specification_info.jl")
include("tables/util.jl")
include("plots/util.jl")
include("plots/plots.jl")
include("plots/plot_predictive_densities.jl")
include("hs_posterior_values.jl")
include("drivers_em.jl")
