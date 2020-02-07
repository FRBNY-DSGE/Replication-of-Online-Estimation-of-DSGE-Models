#!/bin/bash
#SBATCH --job-name=MASTER_PRED
#SBATCH --partition=short

for pr in {diffuse,standard}
do
    mkdir $pr
    cd $pr
    for cond in {bluechip,neither,nowcast,nowcast_bluechip}
    do
        mkdir $cond
        cd $cond
        for m in {sw,swff,swpi}
        do
            mkdir $m
            cd $m
            echo $pr
            echo $cond
            echo $m
            mkdir point
            cd point
            cp ../../../../batch_pred_dens.sh .
            sbatch -J ${m}${cond} batch_pred_dens.sh $pr $cond $m point
            cd ..
            mkdir nonpoint
            cd nonpoint
            cp ../../../../batch_pred_dens.sh .
            sbatch -J ${m}${cond} batch_pred_dens.sh $pr $cond $m nonpoint
            cd ..
            #sleep 180
            cd ..
        done
        cd ..
    done
    cd ..
done
