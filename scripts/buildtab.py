#!/usr/bin/python3

import pandas as pd
import math
import spot
import sys

if len(sys.argv) != 2:
    print("syntax: buildtab input.csv")
    exit(2)

csv = pd.read_csv(sys.argv[1], index_col=['formula', 'tool'])
l = list(csv.index.levels[0])
t = ['ltl2dstar', 'ltl3dra', 'rabinizer', 'DRA1', 'DRA2', 'DRA3']


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
\begin{tabular}{lrrrrrr}""")
print("\\texttt{" + sys.argv[1] + '}\\\\');
for j in t:
    print("&", j, end='')
print("\\\\")
for i in l:
    print('$' + spot.formula(i).to_str('latex') + '$', end=' ')
    for j in t:
        try:
            data = csv.loc[i,j]
            val = data.states
            if math.isnan(val):
                if data.exit == -1:
                    val = 'timeout'
                else:
                    val = 'imposs'
            else:
                val = str(int(val))
                if not j.startswith('DRA'):
                    val += ' (' + str(int(data.acc)) + ')'
        except KeyError:
            val = 'na'
        print("&", val, end=' ')
    print("\\\\")
print("""\end{tabular}
\end{document}""")
