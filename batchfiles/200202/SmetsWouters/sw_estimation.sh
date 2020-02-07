#!/bin/bash
#SBATCH --partition=normal
#SBATCH --nodes=6
#SBATCH --ntasks-per-node=16
#SBATCH --time=48:00:00

module load julia/1.1.0

export JULIA_WORKER_TIMEOUT=300
#generate nodefile to use the IB network
rm -f nodefile
for i in `srun -n $SLURM_NTASKS hostname |sort`
do echo $i-ib0 >> nodefile
done

#first arg: num procs
#second arg: est_spec
#third arg: iteration number
echo $1
echo $2
julia ../../specSmetsWout_N_MH=1_3_5.jl 96 $1 $2
