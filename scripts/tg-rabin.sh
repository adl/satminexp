#!/bin/sh

# Timeout for SAT-based minimization in sec.
TIMEOUT=${TIMEOUT:=300}
# Max number of parallel jobs
MAXJOBS=${MAXJOBS:=4}

# This is the code for a single jobs, i.e., it receives one formula,
# translates it for all tools, and minimizes it for different Rabin
# acceptances.
if test $# = 1; then
    line=$1
    IFS=, read f rest
    output=TGR-$line.csv
    eval $rest

    : > $output

    # Run ltl3dra
    out=ltl3dra-TGR-$line.hoa
    ltldo -f "$f" 'ltl3dra -H2' --name=%r -H >$out
    acc=`autfilt --cleanup-acc $out -H | grep acc-name | cut -d: -f2`
    acc=${acc:=other}
    autfilt $out --stats="$f,ltl3dra,%S,%E,$acc,%p,0,%M,%F" >> $output || exit 0

    if ltldo -H --timeout=$TIMEOUT -f "$f" >ltl3dra-sat-TGR$pairs-$line.hoa \
	     "autfilt -C -H --cleanup-acc --sat-minimize ltl3dra-TGR-$line.hoa --name=%%r >%O #%f"; then

	if ! autfilt ltl3dra-sat-TGR$pairs-$line.hoa \
	     --stats="$f,ltl3dra-min,%S,%E,$acc,%p,0,%M,%F" >> $output; then
	    echo "$f,ltl3dra-min,,,,,-1,," >> $output
	fi
    else
	echo "$f,ltl3dra-min,,,,,$?,," >> $output
    fi

    # Run Rabinizer 3.1
    out=rabinizer-TGR-$line.hoa
    ltldo -f "$f" 'rabinizer -format=hoa -auto=tgr -silent -out=std %f >%H' --name=%r -H >$out
    acc=`autfilt --cleanup-acc rabinizer-TGR-$line.hoa -H | grep acc-name | cut -d: -f2`
    acc=${acc:=other}
    autfilt rabinizer-TGR-$line.hoa \
	    --stats="$f,rabinizer,%S,%E,$acc,%p,0,%M,%F" >> $output

    if ltldo -H --timeout=$TIMEOUT -f "$f" >rabinizer-sat-TGR-$line.hoa \
	     "autfilt -C -H --cleanup-acc --sat-minimize rabinizer-TGR-$line.hoa --name=%%r >%O #%f"; then
	if ! autfilt rabinizer-sat-TGR-$line.hoa \
	     --stats="$f,rabinizer-min,%S,%E,$acc,%p,0,%M,%F" >> $output; then
	    echo "$f,rabinizer-min,,,,,-1,," >> $output
	fi
    else
	echo "$f,rabinizer-min,,,,,$?,," >> $output
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
(echo 'formula,tool,states,edges,acc,complete,exit,time,automaton'
cat TGR-*.csv) > tg-rabin.csv
