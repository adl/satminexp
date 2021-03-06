#!/bin/sh

set -e  # Abort on any error
set -x  # Show each instruction at is it run

# LTL2BA
V=1.2b1
wget http://www.lsv.ens-cachan.fr/~gastin/ltl2ba/ltl2ba-$V.tar.gz
tar xvf ltl2ba-$V.tar.gz
cd ltl2ba-$V
make -j4
mv ltl2ba /usr/local/bin/
cd ..
rm -rf ltl2ba-$V ltl2ba-$V.tar.gz

# LTL3DRA
V=0.2.2
wget http://sourceforge.net/projects/ltl3dra/files/ltl3dra-$V.tar.gz
tar xvf ltl3dra-$V.tar.gz
cd ltl3dra-$V
make -j4
mv ltl3dra /usr/local/bin/
cd ..
rm -rf ltl3dra-$V ltl3ba-$V.tar.gz

# ltl2dstar
V=0.5.3
wget http://www.ltl2dstar.de/down/ltl2dstar-0.5.3.tar.gz
tar xvf ltl2dstar-$V.tar.gz
cd ltl2dstar-$V/src
make -j4
mv ltl2dstar /usr/local/bin/
cd ..

# glugose 4.0
wget http://www.labri.fr/perso/lsimon/downloads/softwares/glucose-syrup.tgz
tar xvf glucose-syrup.tgz
cd glucose-syrup/simp
make -j4
mv glucose /usr/local/bin
cd ../..
rm -rf glucose-syrup

## Plingeling
## -- disabled until we need it.  The website did not respond on 2015-07-11
# V=ayv-86bf266-140429
# wget http://fmv.jku.at/lingeling/plingeling-$V.zip
# mkdir plingeling
# cd plingeling
# unzip ../plingeling-$V.zip
# ./build.sh
# mv binary/plingeling /usr/local/bin
# cd ..
# rm -rf plingeling plingeling-$V.zip

# Rabinizer 3.1
wget https://www7.in.tum.de/~kretinsk/rabinizer3/rabinizer3.1.jar
mv rabinizer3.1.jar /usr/local/bin/rabinizer.jar
cat >/usr/local/bin/rabinizer <<\EOF
#!/bin/sh
exec java -jar /usr/local/bin/rabinizer.jar "$@"
EOF
chmod +x /usr/local/bin/rabinizer
