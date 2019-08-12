set terminal pdf font ',20'

       set grid lw 0.1
       set size 1,1.06
       set title ''
       set xtics font 'Verdana, 21'
       set ytics font 'Verdana, 21'
       show grid
       set key font 'Verdana, 22' spacing 1 top right out
       set boxwidth 0.75
       set style fill solid
       set xtics rotate
       set key opaque

      set yrange [98:100]
#     set ytics 0, 0.2, 1
#     set xtics (0.9, 0.99, 0.999, 0.999, 0.9999)
      set style data histogram
      set style histogram cluster gap 1
      set bmargin 4
      set lmargin 11
      set tmargin 3
      set nokey

set output '../plots/coverage.pdf'
set ylabel 'Scenario Coverage (%)' font 'Verdana, 26' offset -.6,-.4
plot '../data/scenario_coverage'  using (100*$3):xtic(1) title col, \
                              '' using (100*$4):xtic(1) title col, \
                              '' using (100*$5):xtic(1) title col, \
                              '' using (100*$6):xtic(1) title col, \
