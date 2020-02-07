using DSGE, DataFrames, DataStructures
using ModelConstructors
import DSGE: rawpath, workpath, tablespath, figurespath, load_fred_data, quartertodate
using Dates, Plots
using CSV, FredData, MAT
srcdir = dirname(@__FILE__)

# Copied from Realtime.jl
# 1 indicate swe compare to January, April, July, and October blue chip forecasts. 3 indicates march, june, september, and december.
BLUECHIP_FORECAST_MONTH = 1
#  REALTIME_DATA_DIR = "$DIR/realtime"
#REALTIME_DATA_DIR = "$(SMC_DIR)/save/realtime"

# Realtime code
include(joinpath(srcdir, "util.jl"))
include(joinpath(srcdir, "data", "data.jl"))
include(joinpath(srcdir, "forecast", "reference_forecasts.jl"))

# Initialize Fred object
if !@isdefined fred
    const fred = Fred()
end
