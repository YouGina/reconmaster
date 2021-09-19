source ~/.profile
sort -T /mnt/dataset/tmp -u $1 -o $1
axiom-scan $1 -m assetfinder -o assetfinder_$1
rm -r ~/.axiom/logs/*