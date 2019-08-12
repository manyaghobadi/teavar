set terminal pdf font ',20'

      set grid lw 0.1
      set size 1,1
      set title ''
      set xtics font 'Verdana, 20'
      set ytics font 'Verdana, 20'
      show grid
      set key font 'Verdana, 24' spacing 1 top right outside
      set boxwidth 0.75
      set style fill solid
      set xtics rotate
      set key opaque

      set yrange [0:16]
      set xrange [-1:8]
#     set ytics 0, 0.2, 1
#     set xtics (0.9, 0.99, 0.999, 0.999, 0.9999)
      set style data histogram
      set style histogram cluster gap 1

set output '../plots/probability_noise.pdf'
set ylabel 'Percent Error (%)' font 'Verdana, 26' offset -.6,0
set nokey

#plot "../data/probability_noise" u (column(0)):(100*$2):3:xtic(1) w boxes lc variable,
plot "../data/probability_noise" u (column(0)):(100*$2):xtic(1) w boxes,
