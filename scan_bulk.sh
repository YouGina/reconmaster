source ./functions.sh

zcat $1 > ${1}.tmp
f=${1}.tmp
axiom-scan $f -m massdns -o massdns_$f
cleanupmassdns massdns_$f
split --bytes=200M cleaned ../split/split
for s in $(ls ../split/split*); do
	sendrequest $s
done
rm massdns_$f
rm ../split/*
rm $f
rm $1
rm -r ~/.axiom/logs/*

