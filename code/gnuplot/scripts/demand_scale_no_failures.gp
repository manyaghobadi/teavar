set terminal pdf font ',20'
       set grid lw 0.1
       set size 1,1
       set title ''
       set xtics font 'Verdana, 25'
       set ytics font 'Verdana, 25'
       show grid
       set key font 'Verdana, 25' spacing 1 top right
       set boxwidth 0.75
       set style fill solid
       set xtics rotate
      set yrange [0:3.4]
#     set ytics 0, 0.2, 1
#     set xtics (0.9, 0.99, 0.999, 0.999, 0.9999)
set bmargin 5

set output '../plots/demand_scale_no_failures.pdf'

set ylabel 'Demand Scale' font 'Verdana, 25' offset -.6,0
# set xlabel '' font 'Verdana, 16' offset -.4,0

set nokey
plot "../data/demand_scale_no_failures" u (column(0)):2:3:xtic(1) w boxes lc variable,
