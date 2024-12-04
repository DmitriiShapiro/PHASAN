#!/usr/bin/env bash

base="outfiles"
# PHITS-generated output file name
f=flux_at_the_end_of_chan.out
# the corresponding ROOT file name
root=${f%.*}.root

# convert $f to .root
parallel "cd {} && angel2root $f" ::: $base/*

# temporary file name for the sum file
sum=$(mktemp -u).root

# sum results of all runs and save them into the $sum file
hadd -f $sum $base/*/$root

# number of ROOT files
n=$(ls -1 $base/*/$root|wc -l)

# divide $sum to $n to get average and save results in the $root file
scale -n $n -o $root $sum

rm -f $sum
