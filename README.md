# SecurityTrails x Amass ReconMaster contest

In this little write-up I'll try to explain shortly what I did to be able to get to the ninth place of the SecurityTrails ReconMaster contest.

Throughouth the contest I tried to keep it as simple as possible.

* Find subdomains for not too well-known domains (using assetfinder)
* Extract words from the discovered subdomains (split by dots and dashes; using a custom script)
* Generate permutations based on the found words (using DNSCewl and custom scripts)
* Resolve the generated permutations to either A or CNAME records (using massdns)

My biggest challenge was the lack of memory and storage space required to generate the permutations. This I solved by splitting big files into smaller chunks and and run it in batches. Also switching between my laptop and VPS running different parts of the iteration helped too. To manage this I created a bunch of custom scripts.

As this was a contest for SeucrityTrails x Amass I did keep one thread of amass running. This was going over a list of 2 letter domains using the custom wordlist I generated. This wordlist kept growing while the steps described earlier iterated.

## Scripts used
I'll go over the scripts that I used now and try to explain them one by one. If you don't have Axiom setup you can comment the axiom line and uncomment the line below:

**find_assets.sh** (run on vps)  
```bash
sort -T /mnt/dataset/tmp -u $1 -o $1
axiom-scan $1 -m assetfinder -o assetfinder_$1
# mkdir assetfinder_$f && cat $f | while read d; do /home/op/go/bin/assetfinder $d | tee -a assetfinder_$f/${d}.txt; done
rm -r ~/.axiom/logs/*
```
This small script takes a file as input and sends it to my axiom instances to use assetfinder to find subdomains. Mostly I used this for the big lists of generated fld's.

**split_fld_assetfinder_results.sh** (run on vps)  
```bash
mkdir ../flds
for i in {0..9}; do
	cat $i* > ../flds/${1}flds_$i
done
for i in {a..z}; do
	for j in {a..z}; do
		cat ${i}${j}* > ../flds/${1}flds_${i}${j}
	done
done
cd ../flds
ls | while read d; do
	sort -T /mnt/g/tmp -u $d -o $d
done
cat * > ${1}flds_full
mkdir split
split -b 500M ${1}flds_full split/${1}flds
cd split
ls | while read d; do
gzip $d
done
```
To have managable files I sometims used this script to create smaller chunks of files which I could use later on. This was also to save storage. Gzipping the text files created files that where about 20% of the original size.

**cewl_files.sh**  (run local)  
```bash
mkdir split_small


ls domains_* -Sr | while read d; do 
touch words/${d}_words
cat $(ls domains_* |grep -v $d) | extract_words_from_domain | grep -v "^com$\|^net$" |anew -q words/${d}_words
sort -u words/${d}_words -o words/${d}_words


DNScewl -l $d --set-list /mnt/e/contest/cleaned/vhosts.txt > cewl_out/${d}_cewl_set; 
DNScewl -l $d --append-list /mnt/e/contest/cleaned/vhosts.txt > cewl_out/${d}_append; 
DNScewl -l $d --prepend-list /mnt/e/contest/cleaned/vhosts.txt > cewl_out/${d}_prepend; 
DNScewl -l $d --set-list words/${d}_words > cewl_out/${d}_words_cewl_set; 
DNScewl -l $d --append-list words/${d}_words > cewl_out/${d}_words_append; 
DNScewl -l $d --prepend-list words/${d}_words > cewl_out/${d}_words_prepend; 

sort -T /mnt/g/tmp -u cewl_out/${d}_cewl_set -o cewl_out/${d}_cewl_set
sort -T /mnt/g/tmp -u cewl_out/${d}_append -o cewl_out/${d}_append
sort -T /mnt/g/tmp -u cewl_out/${d}_prepend -o cewl_out/${d}_prepend
sort -T /mnt/g/tmp -u cewl_out/${d}_cewl_set -o cewl_out/${d}_words_cewl_set
sort -T /mnt/g/tmp -u cewl_out/${d}_append -o cewl_out/${d}_words_append
sort -T /mnt/g/tmp -u cewl_out/${d}_prepend -o cewl_out/${d}_words_prepend

gzip -f cewl_out/${d}_cewl_set
gzip -f cewl_out/${d}_append
gzip -f cewl_out/${d}_prepend

gzip -f cewl_out/${d}_words_cewl_set
gzip -f cewl_out/${d}_words_append
gzip -f cewl_out/${d}_words_prepend

# rm $d
done
```
This is the script I used to generate the permutations using DNSCewl from the generated wordlist and a list of virtual hosts (dev/internal/corp etc.). This script was also responsible for generating the wordlist from the found domains. I exclude .com/.net because otherwise it created too much big files to process at all. I left in other extensions to generate fld's for those.  

A small thing that might need explanation is on line 6. This part extracts the words from all domains, except the one it is working on. This is so that DNSCewl wont make permutations for all the known words for the current domain, but makes permutations on positions of words it finds out of the other list and replaces it with all the words from the list.   

I also append/prepend with the both lists.

**split_big_files_cleanup_small_files.sh** (run local)  
```bash
grep -Hrni "no target" | awk -F':' '{print $1}' | while read f; do
	rm $f;
done


find . -size +100M | while read f; do
	split -b 100M $f ./${f}_split; rm $f;
done
```
DNSCewl generated super large files which where to big to consume as is. Also, not all domains contains subdomains so there where some empty files. This little script was responsible for some cleanup. Removing the empty results and splitting large files into consumable chunks.  
After cleanup I manually uploaded these files to my VPS again.

**functions.sh** (run on vps)  
```bash
cleanupmassdns() {
        input=$1
        cat $input | awk '{print $1}' | sed 's/.$//' > cleaned
	cp cleaned ../cleaned_copy & (cat ../cleaned_copy | extract_fld | anew ../flds && while read fld; do parseflds $fld | tee -a ../assets; done) & 
}

sendrequest() {
        input_file=$1
        sort -u $input_file -o $input_file
        cat $input_file | gzip > ${input_file}.tmp
        gzip $input_file
        input_file=${input_file}.tmp
        response=$(curl -X POST      --url "https://api.securitytrails.com/v1/submit/hostnames" -H 'Content-Encoding: gzip'  --header 'APIKEY: $SECURITYTRAILS_TOKEN'      --data-binary "@$input_file");
        if [[ $response == *"has been exceeded"* ]]; then
                echo "Waiting one hour because:"
                echo $response
                secs=$((60 * 60))
                while [ $secs -gt 0 ]; do
                        echo -ne "$secs\033[0K\r"
                        sleep 1
                        : $((secs--))
                done
                sendrequest $input_file | tee -a curl_out
        else
                echo $response
        fi;
}

masscheckandsend() {
	massdns -w massdns -o S -r /mnt/dataset/lists/resolvers.txt $1
	cat massdns | awk '{print $1}' | sed 's/.$//' > cleaned
	split -b 50m cleaned split/split
	for cf in $(ls split/*); do
		sort -u $cf -o $cf
		sendrequest $cf
	done
	rm split/*
}

rundnscewl() {
	domain=$1
	~/tools/discovery/DNSCewl/DNScewl --target-list=$domain --append-list=../../../lists/vhosts.txt > dnscewl/$domain
	masscheckandsend dnscewl/$domain
	~/tools/discovery/DNSCewl/DNScewl --target-list=$domain --prepend-list=../../../lists/vhosts.txt > dnscewl/$domain
	masscheckandsend dnscewl/$domain
	~/tools/discovery/DNSCewl/DNScewl --target-list=$domain --set-list=../../../lists/vhosts.txt > dnscewl/$domain	
	masscheckandsend dnscewl/$domain
	~/tools/discovery/DNSCewl/DNScewl --target-list=$domain --set-list=words > dnscewl/$domain
	masscheckandsend dnscewl/$domain

	rm dnscewl/$domain
	rm assets_new
}

```
I've been playing quite a bit with different methods, but some functionaly was similar every time. For that I used this file to include the functions:
- cleanupmassdns - to get the resolved domains without ip address or cname
- sendrequest - to send the request to securitytrails
- masscheckandsend - resolve the generated domains, this function is later replaced with axiom
- rundnscewl - one of my first functions which I later stopped using, as the files became to big for my vps

**parseflds.sh** (run local)  
```bash
input=$1;
d=$(dig +nocmd $input any +short);

if [[ $d ]]; then
	echo $input
fi
```
The cleanupmassdns function uses this file to do a quick resolve on the flds. If it does resolve it is later used in a new iteration to find subdomains and then create permutations again.

**scan_test.sh** (run on vps)  
```bash
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
```
This script was used to try out new methods. I think this version is one of the earlier things I tried as I undo most of my changes every time. Thought it's nice to include in this repository.

**scan_top50.sh** (run on vps)  
```bash
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
```
This script, also more in the beginning of the contest, was used to go over the alexa top 50 domains which lived in the asset file. For every domain run assetfinder, subfinder and shuffledns. For shuffledns I used a wordlist which was already generated out of the earlier found subdomains, but did not grow yet.

**scan_bulk.sh** (run on vps)  
```bash
source ./functions.sh

zcat $1 > ${1}.tmp
f=${1}.tmp
axiom-scan $f -m massdns -o massdns_$f
# sudo /usr/bin/massdns -r /home/op/lists/resolvers.txt -o S $f -w massdns_$f
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
```
The scan_bulk is basically my final script which I used througout the most part of the contest. It's small compared to the others, because I executed it via custom while loops directly from the command line, instead of having the loops in the script. The input where files generated using the previous scripts which where run locally.   

Most of the work in this script is done via axiom's massdns module, resolving large files with generated domains. 

When resolving is ready the result files are cleaned up (while extracting flds' for the next iteration) and the subdomains are send in to securitytrails.

## word_list file
This is the endresult of all the words generated during the contest, sorted and made unique. Use it well.

## Tools used
- [Amass](https://github.com/OWASP/Amass)
- [Anew](https://github.com/tomnomnom/anew)
- [Assetfinder](https://github.com/tomnomnom/assetfinder)
- [Axiom](https://github.com/pry0cc/axiom) ([See it in use](https://www.youtube.com/watch?v=t-FCvQK2Y88))
- [DNSCewl](https://github.com/codingo/DNSCewl)
- [Massdns](https://github.com/blechschmidt/massdns)
- [ShuffleDNS](https://github.com/projectdiscovery/shuffledns)
- [Subfinder](https://github.com/projectdiscovery/subfinder)


### Installation of the tools:
Installation of tools:

```sudo snap install amass```
```go get -u github.com/tomnomnom/anew```
```go get -u github.com/tomnomnom/assetfinder```
```GO111MODULE=on go get -u -v github.com/projectdiscovery/shuffledns/cmd/shuffledns```
```GO111MODULE=on go get -u -v github.com/projectdiscovery/subfinder/v2/cmd/subfinder```

```
git clone https://github.com/blechschmidt/massdns.git
cd massdns
make
sudo make install
```

```
git clone https://github.com/codingo/dnscewl.git
sudo cp dnscewl/DNScewl /usr/bin/DNScewl
```
