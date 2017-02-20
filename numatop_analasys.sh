#!/bin/bash

# Process output of the numatop utility 
# echo "N" | numatop -d ${BASENAME}.numatop >/dev/null 2>&1 &
# run some benchmark
# pkill -2 numatop
# numatop_analasys.sh output.numatop => creates graph showing CPU utilization on NUMA nodes and RMA/LMA ratio

for file in "$@"
do
# Get number of NUMA nodes and print header
  paragrep NODE "$file"  2>/dev/null | grep -v "NODE\|Overview" | awk 'BEGIN {RS="\n\n";FS="\n";} NR==1 {exit} END {ORS=""; for (i = 0; i <= NF; i++) { print "\"RMA/LMA node ",i,"\"\t\"CPU util. node ",i,"\"\t"}; printf "\n"}' > "${file}.column"
#print Data  
  paragrep NODE "$file"  | grep -v "NODE\|Overview" | tr -s " " | sed "s/^[ \t]*//" | tr " " "\t" | awk '$0 != "" {printf "%s\t%s\t",$6,$7} $0 == "" {printf "\n"}' >> "${file}.column"
  paragrep NODE "$file"  2>/dev/null | grep -v "NODE\|Overview" | wc -l 
  COLUMNS=$(tail -1 ${file}.column | awk '{print NF}')

  echo "Check ${file}.column and ${file}.png output"

#set terminal x11 size 1600,800 noenhanced
  gnuplot -persist <<-EOFMarker
set terminal png size 1600,800
set output "${file}.png"
set multiplot layout 2, 1 title "NUMATOP file ${file}" noenhanced
set title "Average CPU utilization on NUMA nodes"
set xlabel "Samples"
set ylabel "CPU utilization in %"
set yrange [0 : 100]
set grid ytics
set ytics 10
plot for [i=2:$COLUMNS:2] "$file.column" u 0:i with linespoints title columnheader
set title "Ratio: Remote Memory Access / Local Memory Access (lower is better)"
set xlabel "Samples"
set ylabel "RMA/LMA"
unset yrange
set ytics autofreq
set autoscale ymax
set logscale y
set grid ytics
plot for [i=1:$COLUMNS:2] "$file.column" u 0:i with linespoints title columnheader

EOFMarker
done

