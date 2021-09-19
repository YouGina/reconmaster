source ./functions.sh


for f in $(shuf asset); do
	echo "Assetfinder"
	assetfinder $f | shuffledns -d $f -wt 100 -r /mnt/dataset/lists/resolvers.txt | tee -a assets_new
	echo "Subfinder"
	subfinder -silent -d $f | shuffledns -d $f -wt 100 -r /mnt/dataset/lists/resolvers.txt | anew assets_new
	cat assets_new |  extract_words_from_domain | sort -u >> words
	sort -u words -o words
	echo "Wordlist"
	shuffledns -silent -d $f -w words -wt 100 -r /mnt/dataset/lists/resolvers.txt | anew assets_new
	sort -u assets_new -o assets_new
	lines=$(wc -l assets_new | awk '{print $1}')

	if [ $lines -ge 30000 ]  ;  then
		sendrequest assets_new
		rundnscewl assets_new
	fi
done
rundnscewl assets_new
