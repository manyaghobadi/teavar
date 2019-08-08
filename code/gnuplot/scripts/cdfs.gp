set terminal pdf font ',20'
       set grid lw 0.1
       set size 1,.7
       set title ''
       set xtics font 'Verdana, 15'
       set ytics font 'Verdana, 15'
       show grid
       set key font 'Verdana, 15' spacing 1 top right outside
       set xrange [-5:105]
       set yrange [0:1]
       set ytics 0, .2, 1
       set xtics 0, 20, 105
       #set xtics ('90%%' .9, '92%%' 0.92, '94%%' 0.94, '96%%' 0.96, '98%%' 0.98, '100%%' 1.0)
       #set xtics 0.9, 0.02, 1
       set output '../plots/cdfs.pdf'

set ylabel 'CDF' font 'Verdana, 14' offset 1,0
set xlabel 'Per Flow Bandwidth (%)' font 'Verdana, 14' offset 0,0

plot \
"../data/guarantees/ffc_1" using (100*$1):2 t 'FFC (k=1)' w lines lw 3,\
"../data/guarantees/ffc_2" using (100*$1):2 t 'FFC (k=2)' w lines lw 3,\
"../data/guarantees/1" using (100*$1):2 t 'TEAVAR ({/Symbol b}=99\%)' w lines lw 3,\
"../data/guarantees/2" using (100*$1):2 t 'TEAVAR ({/Symbol b}=99.9\%)' w lines lw 3,\
"../data/guarantees/3" using (100*$1):2 t 'TEAVAR ({/Symbol b}=99.99\%)' w lines lw 3,\
