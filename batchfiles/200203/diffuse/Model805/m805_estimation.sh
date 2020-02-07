#!/bin/bash
#SBATCH --job-name=SWpi
#SBATCH --partition=normal
#SBATCH --nodes=21
#SBATCH --ntasks-per-node=16
#SBATCH --time=48:00:00

module load julia/1.1.0

export JULIA_WORKER_TIMEOUT=300

rm -f nodefile
for i in `srun -n $SLURM_NTASKS hostname |sort`
do echo $i-ib0 >> nodefile
done


julia ../../../../specfiles/200203/specAll_1991-2017.jl m805 ss4
