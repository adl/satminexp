#!/bin/sh

# Timeout for SAT-based minimization in sec.
TIMEOUT=${TIMEOUT:=300}
# Max number of parallel jobs
MAXJOBS=${MAXJOBS:=4}

# This is the code for a single jobs, i.e., it receive one formula,
# translate it for all tools, and minimize it for different Rabin
# acceptance.
if test $# = 1; then
    line=$1
    IFS=, read f rest
    output=TGR-$line.csv
    eval $rest

    : > $output

    # Run ltl3dra
    ltlfilt -f "$f" -p -s | ltl3dra -H2 -F - > ltl3dra-TGR-$line.hoa
    acc=`autfilt --cleanup-acc ltl3dra-TGR-$line.hoa -H | grep acc-name | cut -d: -f2`
    acc=${acc:=other}
    autfilt ltl3dra-TGR-$line.hoa \
	    --stats="$f,ltl3dra,%S,%E,$acc,%p,0,%F" >> $output || exit 0

    if ltldo -H --timeout=$TIMEOUT -f "$f" >ltl3dra-sat-TGR$pairs-$line.hoa \
	     "autfilt -C -H --cleanup-acc --sat-minimize ltl3dra-TGR-$line.hoa --name=%f >%O"; then

	if ! autfilt ltl3dra-sat-TGR$pairs-$line.hoa \
	     --stats="$f,ltl3dra-min,%S,%E,$acc,%p,0,%F" >> $output; then
	    echo "$f,ltl3dra-min,,,,,-1," >> $output
	fi
    else
	echo "$f,ltl3dra-min,,,,,$?," >> $output
    fi


    rabinizer -format=hoa -auto=tgr -silent -out=std "$(ltlfilt -f "$f" -p)" >rabinizer-TGR-$line.hoa
    # The preversion of rabinizer 3.1 has a bug where it can output a non-deterministic automaton
    # despite declaring "property: deterministic".  So autfilt -q will exit with $?=2 in this case.
    if autfilt -q rabinizer-TGR-$line.hoa; then
	acc=`autfilt --cleanup-acc rabinizer-TGR-$line.hoa -H | grep acc-name | cut -d: -f2`
	acc=${acc:=other}
	autfilt rabinizer-TGR-$line.hoa \
		--stats="$f,rabinizer,%S,%E,$acc,%p,0,%F" >> $output

	if ltldo -H --timeout=$TIMEOUT -f "$f" >rabinizer-sat-TGR-$line.hoa \
		 "autfilt -C -H --cleanup-acc --sat-minimize rabinizer-TGR-$line.hoa --name=%f >%O"; then
	    if ! autfilt rabinizer-sat-TGR-$line.hoa \
		 --stats="$f,rabinizer-min,%S,%E,$acc,%p,0,%F" >> $output; then
		echo "$f,rabinizer-min,,,,,-1," >> $output
	    fi
	else
	    echo "$f,rabinizer-min,,,,,$?," >> $output
	fi
    else
	rm -f rabinizer-TGR-$line.hoa
    fi
    exit 0
fi

# Convert the two-argument form into a one-argument form, passing the
# second one on stdin.
if test $# = 2; then
    echo "$2" | $0 $1
    exit $?
fi


# Cleanup
rm -f *-TGR-*.hoa *-TGR?-*.hoa TGR-*.csv tg-rabin.csv
# Run all jobs
grep -v '^#' formulas | parallel -j$MAXJOBS $0 '{#}' {}
# Gather results
(echo 'formula,tool,states,edges,acc,complete,exit,automaton'
cat TGR-*.csv) > tg-rabin.csv
