#!/bin/bash
#SBATCH --job-name=MASTER_SW
#SBATCH --partition=short

#est_specs--remove est_spec=5 because it has 6 parameter blocks (used for diffuse prior forecasting)
for e in {1,2,3,4,6,7,8,9,10,11,12,13,14,15,16}
do
    mkdir est_spec_$e
    cd est_spec_$e
    for i in {1..200}
    do
        mkdir $i
        cd $i
        cp ../../sw_estimation.sh .
        sbatch -J SW_e${e}_i${i} sw_estimation.sh $e $i
        echo $est
        echo $i
        cd ..
    done
    cd ..
done
