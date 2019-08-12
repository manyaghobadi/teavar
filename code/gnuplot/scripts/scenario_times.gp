#the 4 lines in y_vals are the four algorihtmn (Tevar with weibull, tevar, smore, ffc)

set terminal pdf font ',20'
       set grid lw 0.1
       set size 1,1
       set title ''
       set xtics font 'Verdana, 25'
       set ytics font 'Verdana, 25'
       show grid
       set key font 'Verdana, 15' spacing 1 top left
       set xtics 0, 20, 120
       set ytics 0, .02, 2
       set yrange[0:.08]

set output '../plots/scenario_times.pdf'
set lmargin 10
set bmargin 4
set ylabel 'Time (s)' font 'Verdana, 30' offset -0.8,0
set xlabel 'Number of Edges' font 'Verdana, 30' offset -1,0
set nokey
plot \
"../data/scenario_times" using 1:4 t 'Cutoff 10^{-4}'  w lines linecolor rgb 'purple' lw 4,\
"../data/scenario_times" using 1:5 t 'Cutoff 10^{-5}'  w lines linecolor rgb 'green' lw 4,\
"../data/scenario_times" using 1:6 t 'Cutoff 10^{-6}'  w lines linecolor rgb 'blue' lw 4,\
"../data/scenario_times" using 1:7 t 'Cutoff 10^{-7}'  w lines linecolor rgb 'orange' lw 4,\
