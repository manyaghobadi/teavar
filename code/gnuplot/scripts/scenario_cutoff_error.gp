set terminal pdf font ',20'

      set grid lw 0.1
      set size 1,1
      set title ''
      set xtics font 'Verdana, 21'
      set ytics font 'Verdana, 21'
      show grid
      set key font 'Verdana, 24' spacing 1 top right outside
      set boxwidth 0.75
      set style fill solid
      set xtics rotate
      set key opaque

      set yrange [0:4.3]
      set xrange [-1:3.6]
#     set ytics 0, 0.2, 1
#     set xtics (0.9, 0.99, 0.999, 0.999, 0.9999)
      set style data histogram
      set style histogram cluster gap 1
      set nokey
      set bmargin 4

set output '../plots/scenario_cutoff_error.pdf'
set ylabel 'Percent Error (%)' font 'Verdana, 26' offset -.6,0
      #set nokey

plot '../data/scenario_cutoff_error' using (100*$2):xtic(1) title col, \
                              '' using (100*$3):xtic(1) title col, \
                              '' using (100*$4):xtic(1) title col, \
                              '' using (100*$5):xtic(1) title col, \
