set terminal pdf font ',20'
       set grid lw 0.1
       set size 1,1
       set title ''
       set xtics font 'Verdana, 25'
       set ytics font 'Verdana, 25'
       show grid
       set key font 'Verdana, 25' spacing 1 top right out
       set yrange [98:100]
       set xrange [1:2.6]
       set xtics 1, 0.4, 3.5
       set ytics 95, 1, 100
       #set xtics (97, 97.5, 98, 98.5, 99, 99.5, 100)
       set tmargin 2
       set nokey
set output '../plots/IBM_o_availability.pdf'

set xlabel 'Demand Scale' font 'Verdana, 25' offset -1,0
set ylabel 'Availability (%)' font 'Verdana, 25' offset -0.6,0
#set title 'Oblivious paths' font 'Verdana, 22' offset 0,1.7
plot \
"../data/availability_o/IBM_o_availability" using 1:(100*$5) t 'SMORE' w lp ps 1.6 linecolor rgb '#ED2838' lw 4,\
"../data/availability_o/IBM_o_availability" using 1:(100*$8) t 'ECMP' w lp ps 1.6  linecolor rgb '#05ba86' lw 4,\
"../data/availability_o/IBM_o_availability" using 1:(100*$11) t 'FFC-1' w lp ps 1.6 linecolor rgb '#E59F00' lw 4,\
"../data/availability_o/IBM_o_availability" using 1:(100*$17) t 'FFC-2' w lp ps 1.6 linecolor rgb '#5bc0f7' lw 4,\
"../data/availability_o/IBM_o_availability" using 1:(100*$14) t 'MaxMin' w lp ps 1.6 linecolor rgb '#8d00ce' lw 4,\
"../data/availability_o/IBM_o_availability" using 1:(100*$2) t 'TEAVAR' w lp ps 1.6 linecolor rgb 'black' lw 4,\


#green: #05ba86
#blue: #5bc0f7
#orange: #E59F00
#purple: #8d00ce
#yellow: #efe441
#red: #ED2838
