set terminal pdf font ',20'
       set grid lw 0.1
       set size 1,1
       set title ''
       set xtics font 'Verdana, 15'
       set ytics font 'Verdana, 15'
       show grid
       set key font 'Verdana, 15' spacing 1 top right
       set xrange [0.9:1]
       set yrange [0:2]
       set ytics 0, .5, 2
#      set xtics (0.9, 0.99, 0.999, 0.999, 0.9999)
       set xtics ('90%%' .9, '92%%' 0.92, '94%%' 0.94, '96%%' 0.96, '98%%' 0.98, '100%%' 1.0)
       #set xtics 0.9, 0.02, 1
       set key left top
       set output '../plots/path_selection.pdf'

set ylabel 'CVaR_{/Symbol b} (% Loss)' font 'Verdana, 18' offset 1,0
set xlabel '{/Symbol b}' font 'Verdana, 20' offset 0,0

plot \
"../data/path_selection" using 1:2 t 'TEAVAR\_oblivious' w lines linecolor rgb '#000000' lw 3,\
"../data/path_selection" using 1:3 t 'TEAVAR\_edge\_disjoint' w lines linecolor rgb '#ED2939' lw 3,\
"../data/path_selection" using 1:4 t 'TEAVAR\_ksp3' w lines linecolor rgb '#FF9B42' lw 3,\
"../data/path_selection" using 1:5 t 'TEAVAR\_ksp4' w lines linecolor rgb '#50C878' lw 3,\
