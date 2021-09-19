source ./functions.sh

while read d; do
	echo "Running for: $d"
	assetfinder $d >> massdns_out
	grep $d dnscewl | shuffledns -d $d -wt 100 -r /mnt/dataset/lists/resolvers.txt -silent >> massdns_out
	lines=$(wc -l massdns_out | awk '{print $1}')
        if [ $lines -ge 30000 ]  ;  then
		split -b 50m massdns_out split/split
		for cf in $(ls split/*); do
                	sort -u $cf -o $cf
	                sendrequest $cf
		done
		rm split/*
		rm massdns_out
		touch massdns_out
	fi;
done<flds
