#!/usr/bin/python3

import pandas as pd
import math
import spot
import sys

if len(sys.argv) != 3:
    print("syntax: buildtab-st s-rabin.csv t-rabin.csv")
    exit(2)

csv_s = pd.read_csv(sys.argv[1], index_col=['formula', 'tool'])
l = list(csv_s.index.levels[0])
ts = ['ltl2dstar', 'ltl3dra', 'rabinizer', 'DRA1']
tt = ['rabinizer', 'DRA1']

csv_t = pd.read_csv(sys.argv[2], index_col=['formula', 'tool'])


print(r"""\documentclass{standalone}
\usepackage{amsmath}
\usepackage{colortbl}
\definecolor{mygray}{gray}{0.75} % 1 = white, 0 = black
\definecolor{lightgray}{gray}{0.7} % 1 = white, 0 = black
\def\E{\cellcolor{mygray}}
\def\P{\cellcolor{red}}
\def\PP{\cellcolor{yellow}}
\def\F{\mathsf{F}} % in future
\def\G{\mathsf{G}} % globally
\def\X{\mathsf{X}} % next
\DeclareMathOperator{\W}{\mathbin{\mathsf{W}}} % weak until
\DeclareMathOperator{\M}{\mathbin{\mathsf{M}}} % strong release
\DeclareMathOperator{\U}{\mathbin{\mathsf{U}}} % until
\DeclareMathOperator{\R}{\mathbin{\mathsf{R}}} % release

\begin{document}
\begin{tabular}{l|rrrr|rr}""")
print("\\multicolumn{7}{l}{\\texttt{" + sys.argv[1] + '} and \\texttt{' + sys.argv[2] + '}}\\\\');
print("&\\multicolumn{4}{c}{state-based acceptance}&\\multicolumn{2}{c}{transition-based acc.} \\\\")
for j in ts:
    print("&", j, end='')
for j in tt:
    print("&", j, end='')
print("\\\\")

def print_half_line(formula, csv, tools):
    global mins
    for j in tools:
        try:
            data = csv.loc[formula,j]
            val = data.states
            if math.isnan(val):
                if data.exit == -1:
                    val = 'timeout'
                else:
                    val = 'imposs'
            else:
                s = int(val)
                val = str(s)
                if not j.startswith('DRA'):
                    if s < mins:
                        mins = s
                else:
                    if s < mins:
                        val = '\\E ' + val
                val += ' (' + str(int(data.acc)) + ')'
        except KeyError:
            val = 'na'
        print("&", val, end=' ')
    

for i in l:
    mins = 999999
    print('$' + spot.formula(i).to_str('latex') + '$', end=' ')
    print_half_line(i, csv_s, ts)
    print_half_line(i, csv_t, tt)
    print("\\\\")
print("""\end{tabular}
\end{document}""")
