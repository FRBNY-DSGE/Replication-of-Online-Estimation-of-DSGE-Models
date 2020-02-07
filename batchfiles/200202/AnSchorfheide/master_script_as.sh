#!/bin/bash
#SBATCH --job-name=MASTER_AS
#SBATCH --partition=short

for e in {1..24}
do
    mkdir est_spec_$e
    cd est_spec_$e
    for i in {1..400}
    do
        mkdir $i
        cd $i
        cp ../../as_estimation.sh .
        sbatch -J AS_e${e}_i${i} as_estimation.sh $e $i
        echo $est
        echo $i
        cd ..
    done
    cd ..
done
