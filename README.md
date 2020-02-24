# SMC Paper Replication
The code in this repository replicates "Online Estimation of DSGE Models" by Michael Cai, Marco Del Negro, Edward Herbst, Ethan Matlin, Reca Sarfati, and Frank Schorfheide. In general, most of the computation code is structured to run in batch mode in parallel on a large cluster, while the plotting code is structured to be run using a single core.

This repository is designed primarily to replicate the figures and tables in the "Online Estimation" paper. **If you are interested in using SMC for your own models, check out our independent software package [SMC.jl](https://github.com/FRBNY-DSGE/SMC.jl)**

Note: To re-run all exercises in the paper could take many weeks with thousands of coures. Hence, we've modularized the replication codes for ease of use because:
1. Many clusters impose time limits on jobs--hence it may be necessary for users to run the replication chunk by chunk
2. Some users may want to focus on particular sections rather than "pressing a button and having the whole shebang run."

Make sure you're using the latest versions of all our packages!
- `DSGE.jl` v1.1.1
- `SMC.jl` v0.1.4
- `StateSpaceRoutines.jl` v0.3.1
- `ModelConstructors.jl` v0.1.8
- To add packages, in the Julia REPL, type `]add PACKAGENAME`

To add all packages you need, enter the following into the Julia REPL:

`]add DSGE SMC StateSpaceRoutines ModelConstructors BenchmarkTools CSV Calculus ClusterManagers ColorTypes DataFrames DataStructures Dates DelimitedFiles DiffEqDiffTools DifferentialEquations Distributed Distributions FFTW FileIO ForwardDiff FredData GR HDF5 InteractiveUtils JLD2 KernelDensity LinearAlgebra MAT MbedTLS Measures Missings NLSolversBase Nullables Optim OrderedCollections PDMats PackageCompiler Plots Printf Query Random RecipesBase Roots SharedArrays SparseArrays SpecialFunctions Statistics StatsBase StatsFuns StatsPlots Test TimeZones Tracker`


## SECTION 4 COMPUTATION
WARNING: Running all 400 simulations of AS and 200 simulations of SW takes multiple days using >12,000 cores and produces 1.1 TB of output. 
To reduce the number of simulations: 
- Go to line 9 of `batchfiles/200202/AnSchorfheide/master_script_as.sh` to the number of simulations you want (currently 400)
- Go to line 10 of `batchfiles/200202/SmetsWouters/master_script_sw.sh` to the number of simulations you want (currently 200)

To re-run the simulations for sections 4.1 and 4.2:
(this code has been run and tested using a slurm scheduler and Julia 1.1.0 on BigTex)
- Go to `batchfiles/200202/AnSchorfheide`
- Change line 10 of `specAnSchorf_N_MH=1_3_5.jl` to the path where you git cloned the repo. (e.g. If the directory you git cloned is `~/user/work/SMC_Paper_Replication/`, you should set this line to `~/user/work/SMC_Paper_Replication/`)
- Run (`sbatch` if uisng slurm scheduler) `master_script_as.sh`. This launches the 400 estimations of AS for each alpha x N_MH combination.

- Go to `batchfiles/200202/SmetsWouters`. 
- Change line 10 of `specsmetsWout_N_MH=1_3_5.jl` to the path where you git cloned the repo. (e.g. if the directory you git cloned is `~/user/work/SMC_Paper_Replication/`, you should set this line to `~/user/work/SMC_Paper_Replication/`)
- Run (`sbatch` if uisng slurm scheduler) `master_script_sw.sh`. This launches the 200 estimations of SW for each alpha x N_MH combination.
- The output is saved in `save/200202`. This output is read in by `estimation_section.jl`

To re-run the simulations for section 4.3:
(this code has been run and tested using a SGE scheduler and Julia 1.1.1 on the FRBNY RAN)
- Go to `specfiles/200201`
- Change line 19 of `specAnSchorfheideExercise.jl` to the path where you git cloned the repo (see example in section above)
- Run `specAnSchorfheideExercise.jl` with at least 100 GB memory on the head worker. The Julia script adds 48 workers (with 3GB memory each). You'll need to modify the lines which add workers to your local cluster.
- This saves the estimation simulations in `save/200201` and also makes the plots based on these simulations (also saved in `save/200201`)

## SECTION 5 COMPUTATION
To re-run the realtime estimations of SW, SWFF, SWpi used in section 5:
(this code has been run and tested using a slurm scheduler and Julia 1.1.0 on BigTex)
- Change line 6 of `specfiles/200203/specAll_1991-2017.jl` to the directory where you git cloned the repo
- Go to `batchfiles/200203`
- Run (`sbatch` if uisng slurm scheduler) `master.sh`
- They will save in `save/200203`

To re-run predictive densities in section 5:
(this code has been run and tested using a slurm scheduler and Julia 1.1.0 on BigTex)
- Go to `batchfiles/200204/`
- Change line 21 of `specPredDensity.jl` to the path where you git cloned the repo to (see example in first section)
- Run (`sbatch` if using slurm scheduler) `master_script.sh`
- Running this launches separate parallel jobs for different combinations of predictive densities (prior, conditional data, etc.)
- The predictive densities' raw output save to `save/200117`. This data is loaded in by `forecasting_section.jl` to produce the predictive density plots.

## MAKING FIGURES AND TABLES
(this code has been run and tested using Julia 1.1.1 on the FRBNY RAN)
To replicate AS `figures/tables` in section 4:
- Run `estimation_section.jl` with model = `:AS` (line 4)

To replicate SW `figures/tables` in section 4:
- Run `estimation_section.jl` with model = `:SW` (line 4)

To replicate `figures/tables` in section 5:
- Run `forecasting_section.jl`


## Disclaimer

Copyright Federal Reserve Bank of New York. You may reproduce, use, modify, make derivative works of, and distribute and this code in whole or in part so long as you keep this notice in the documentation associated with any distributed works. Neither the name of the Federal Reserve Bank of New York (FRBNY) nor the names of any of the authors may be used to endorse or promote works derived from this code without prior written permission. Portions of the code attributed to third parties are subject to applicable third party licenses and rights. By your use of this code you accept this license and any applicable third party license.

THIS CODE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT ANY WARRANTIES OR CONDITIONS OF ANY KIND, EITHER EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION ANY WARRANTIES OR CONDITIONS OF TITLE, NON-INFRINGEMENT, MERCHANTABILITY OR FITNESS FOR A PARTICULAR PURPOSE, EXCEPT TO THE EXTENT THAT THESE DISCLAIMERS ARE HELD TO BE LEGALLY INVALID. FRBNY IS NOT, UNDER ANY CIRCUMSTANCES, LIABLE TO YOU FOR DAMAGES OF ANY KIND ARISING OUT OF OR IN CONNECTION WITH USE OF OR INABILITY TO USE THE CODE, INCLUDING, BUT NOT LIMITED TO DIRECT, INDIRECT, INCIDENTAL, CONSEQUENTIAL, PUNITIVE, SPECIAL OR EXEMPLARY DAMAGES, WHETHER BASED ON BREACH OF CONTRACT, BREACH OF WARRANTY, TORT OR OTHER LEGAL OR EQUITABLE THEORY, EVEN IF FRBNY HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGES OR LOSS AND REGARDLESS OF WHETHER SUCH DAMAGES OR LOSS IS FORESEEABLE.

