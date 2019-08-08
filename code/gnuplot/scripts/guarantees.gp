set terminal pdf font ',20'
       set grid lw 0.1
       set size 1,1
       set title ''
       set xtics font 'Verdana, 18'
       set ytics font 'Verdana, 18'
       show grid
       set key font 'Verdana, 16' spacing 2 top out center horizontal
       set yrange [0:100]
       set xrange [.5:5.5]
       set ytics 0, 20, 100
       set xtics ("99" 1, "99.9" 2, "99.99" 3, "99.995" 4, "99.999" 5)
       set tmargin 3
       

set output '../plots/guarantees.pdf'
set xlabel 'Availability (%)' font 'Verdana, 18' offset -1,0
set ylabel 'Admissable Bandwidth (%)' font 'Verdana, 18' offset -0.6,0
plot "../data/guarantees_bars" using 1:(100*$2) t 'TEAVAR' w lp ps 1.6 linecolor rgb 'black' lw 4,\
    "../data/guarantees_bars" using 3:(100*$4) t 'FFC-1' w lp ps 1.6 linecolor rgb '#E59F00' lw 4,\
    "../data/guarantees_bars" using 5:(100*$6) t 'FFC-2' w lp ps 1.6 linecolor rgb '#5bc0f7' lw 4,\


#green: #05ba86
#blue: #5bc0f7
#orange: #E59F00
#purple: #8d00ce
#yellow: #efe441
#red: #ED2838
