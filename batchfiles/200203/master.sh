#!/bin/bash
#SBATCH --job-name=master
#SBATCH --partition=short

cd diffuse/SmetsWouters
sbatch sw_estimation.sh
cd ../../diffuse/Model805
sbatch m805_estimation.sh
cd ../../diffuse/Model904
sbatch m904_estimation.sh

cd ../../standard/SmetsWouters
sbatch sw_estimation.sh
cd ../../standard/Model805
sbatch m805_estimation.sh
cd ../../standard/Model904
sbatch m904_estimation.sh
