#the 4 lines in y_vals are the four algorihtmn (Tevar with weibull, tevar, smore, ffc)

set terminal pdf font ',20'
       set grid lw 0.1
       set size 1,1
       set title ''
       set xtics font 'Verdana, 21'
       set ytics font 'Verdana, 21'
       show grid
       set key font 'Verdana, 15' spacing 1 top left
       set yrange[0:120]
       set xrange[20:112]
       set xtics rotate
       set ytics 0, 20, 120
       set xtics nomirror
       set xtics ("B4" 38, "IBM" 48, "MWAN" 75, "ATT" 112)
       set x2tics (38, 48, "75" 75, 112)

set output '../plots/optimizer_times.pdf'
set lmargin 9
set bmargin 3.8
set ylabel 'Time (s)' font 'Verdana, 26' offset -0.8,0
set x2label 'Number of Edges' font 'Verdana, 22' offset -1,0
set nokey
plot \
"../data/optimizer_times" using 1:4 t 'Cutoff 10^{-4}'  w lines linecolor rgb 'purple' lw 4,\
"../data/optimizer_times" using 1:5 t 'Cutoff 10^{-5}'  w lines linecolor rgb 'green' lw 4,\
"../data/optimizer_times" using 1:6 t 'Cutoff 10^{-6}'  w lines linecolor rgb 'blue' lw 4,\
"../data/optimizer_times" using 1:7  t 'Cutoff 10^{-7}'  w lines linecolor rgb 'orange' lw 4,\
