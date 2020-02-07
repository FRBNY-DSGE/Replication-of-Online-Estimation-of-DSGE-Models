#!/bin/bash
#SBATCH --partition=normal
#SBATCH --nodes=7
#SBATCH --ntasks-per-node=16
#SBATCH --time=48:00:00
#SBATCH --nice=100

module load julia/1.1.0

export JULIA_WORKER_TIMEOUT=300
#generate nodefile to use the IB network
rm -f nodefile
for i in `srun -n $SLURM_NTASKS hostname |sort`
do echo $i-ib0 >> nodefile
done
julia ../../../../specPredDensity.jl 112 $1 $2 $3 $4
