set terminal pdf font ',20'
       set grid lw 0.1
       set size 1,1
       set title ''
       set xtics font 'Verdana, 15'
       set ytics font 'Verdana, 15'
       show grid
       set key font 'Verdana, 12' spacing 1 out top center horizontal
       set boxwidth 0.75
       set style fill solid
       #set xtics rotate
       set key opaque

      set xrange [-.6:3.6]
      set yrange [70:100]
#     set ytics 0, 0.2, 1
#     set xtics (0.9, 0.99, 0.999, 0.999, 0.9999)
      set style data histogram
      set style histogram cluster gap 1
      #set lmargin 10
      set tmargin 2.3


set output '../plots/throughput_bars.pdf'
set ylabel 'Throughput (%)' font 'Verdana, 18' offset 1,0
set xlabel 'Availability' font 'Verdana, 20' offset 0,0
plot '../data/throughput_bars'    using (100*$2):xtic(1) title col lc rgb 'black', \
                              '' using (100*$3):xtic(1) title col lc rgb '#ED2838', \
                              '' using (100*$5):xtic(1) title col lc rgb '#05ba86', \
                              '' using (100*$4):xtic(1) title col lc rgb '#E59F00', \
                              '' using (100*$6):xtic(1) title col lc rgb '#8d00ce', \

