sort -T /mnt/dataset/tmp -u $1 -o $1
axiom-scan $1 -m assetfinder -o assetfinder_$1
# mkdir assetfinder_$f && cat $f | while read d; do /home/op/go/bin/assetfinder $d | tee -a assetfinder_$f/${d}.txt; done
rm -r ~/.axiom/logs/*