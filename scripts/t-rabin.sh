#!/bin/sh

# Timeout for SAT-based minimization in sec.
TIMEOUT=${TIMEOUT:=300}
# Max number of parallel jobs
MAXJOBS=${MAXJOBS:=4}

# This is the code for a single jobs, i.e., it receives one formula,
# translates it for all tools, and minimizes it for different Rabin
# acceptance.
if test $# = 1; then
    line=$1
    IFS=, read f rest
    output=TR-$line.csv
    eval $rest

    : > $output

    # Run ltl2dstar using ltl2tgba
    out=ltl2dstar-TR-$line.hoa
    ltldo -f "$f" 'ltl2dstar --ltl2nba=spin:ltl2tgba@-Ds' --name="$f,ltl2dstar,%s,%e,%a,%p,0,%r" -H >$out
    autfilt --stats="%M,%F" $out >> $output

    # Run ltl3dra
    out=ltl3dra-TR-$line.hoa
    ltldo -f "$f" 'ltl3dra -H3' --name="$f,ltl3dra,%s,%e,%a,%p,0,%r" -H >$out
    autfilt --stats="%M,%F" $out >> $output

    # Rabinizer 3.1
    out=rabinizer-TR-$line.hoa
    ltldo -f "$f" 'rabinizer -format=hoa -auto=tr -silent -out=std %f >%H' --name="$f,rabinizer,%s,%e,%a,%p,0,%r" -H >$out
    autfilt --stats="%M,%F" $out >> $output

    for pairs in 1 2 3; do
	# Compute the smallest automaton.  We want the smallest number
	# of acceptance sets, and among those, the smallest number of
	# states, and among those, the smallest number of transitions.
	# We recompute this minimum for each value of $pairs, because
	# if a previous value of $pairs produced an automaton, it is
	# likely to be the one we should use.

	# Also if we have a sat-based minimized automaton for this
	# line, include it in the selection.
	if test -f sat-SR$pairs-$line.hoa; then
	    add=sat-SR$pairs-$line.hoa
	else
	    add=
	fi
	input=`autfilt --cleanup-acc --stats='%a,%s,%t,%F' *-TR*-$line.hoa $add |
               sort          -t, -n -k3,3 |
               sort --stable -t, -n -k2,2 |
               sort --stable -t, -n -k1,1 |
               sed 's/^.*,//;q'`

	opt='acc="Rabin '$pairs'"'
	if ltldo -H --timeout=$TIMEOUT -f "$f" >sat-TR$pairs-$line.hoa \
		 "autfilt -C -H --cleanup-acc --sat-minimize='$opt' $input --name=%%r >%O #%f"; then
	    if ! autfilt sat-TR$pairs-$line.hoa \
		 --stats="$f,DRA$pairs,%S,%E,%A,%p,0,%M,%F" >> $output; then
		echo "$f,DRA$pairs,,,,,-1,," >> $output
	    fi
	else
	    echo "$f,DRA$pairs,,,,,$?,," >> $output
	fi
    done
    exit 0
fi

# Convert the two-argument form into a one-argument form, passing the
# second one on stdin.
if test $# = 2; then
    echo "$2" | $0 $1
    exit $?
fi


# Cleanup
rm -f *-TR-*.hoa *-TR?-*.hoa TR-*.csv t-rabin.csv
# Run all jobs
grep -v '^#' formulas | parallel --bar -j$MAXJOBS $0 '{#}' {}
# Gather results
(echo 'formula,tool,states,edges,acc,complete,exit,time,automaton'
cat TR-*.csv) > t-rabin.csv
