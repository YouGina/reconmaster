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
I'll go over the scripts that I used now and try to explain them one by one:

**find_assets.sh** (run on vps)  
This small script takes a file as input and sends it to my axiom instances to use assetfinder to find subdomains. Mostly I used this for the big lists of generated fld's.

**split_fld_assetfinder_results.sh** (run on vps)  
To have managable files I sometims used this script to create smaller chunks of files which I could use later on. This was also to save storage. Gzipping the text files created files that where about 20% of the original size.

**cewl_files.sh**  (run local)  
This is the script I used to generate the permutations using DNSCewl from the generated wordlist and a list of virtual hosts (dev/internal/corp etc.). This script was also responsible for generating the wordlist from the found domains. I exclude .com/.net because otherwise it created too much big files to process at all. I left in other extensions to generate fld's for those.  

A small thing that might need explanation is on line 6. This part extracts the words from all domains, except the one it is working on. This is so that DNSCewl wont make permutations for all the known words for the current domain, but makes permutations on positions of words it finds out of the other list and replaces it with all the words from the list.   

I also append/prepend with the both lists.

**split_big_files_cleanup_small_files.sh** (run local)  
DNSCewl generated super large files which where to big to consume as is. Also, not all domains contains subdomains so there where some empty files. This little script was responsible for some cleanup. Removing the empty results and splitting large files into consumable chunks.  
After cleanup I manually uploaded these files to my VPS again.

**functions.sh** (run on vps)  
I've been playing quite a bit with different methods, but some functionaly was similar every time. For that I used this file to include the functions:
- cleanupmassdns - to get the resolved domains without ip address or cname
- sendrequest - to send the request to securitytrails
- masscheckandsend - resolve the generated domains, this function is later replaced with axiom
- rundnscewl - one of my first functions which I later stopped using, as the files became to big for my vps

**parseflds.sh** (run local)  
The cleanupmassdns function uses this file to do a quick resolve on the flds. If it does resolve it is later used in a new iteration to find subdomains and then create permutations again.

**scan_test.sh** (run on vps)  
This script was used to try out new methods. I think this version is one of the earlier things I tried as I undo most of my changes every time. Thought it's nice to include in this repository.

**scan_top50.sh** (run on vps)  
This script, also more in the beginning of the contest, was used to go over the alexa top 50 domains which lived in the asset file. For every domain run assetfinder, subfinder and shuffledns. For shuffledns I used a wordlist which was already generated out of the earlier found subdomains, but did not grow yet.

**scan_bulk.sh** (run on vps)  
The scan_bulk is basically my final script which I used througout the most part of the contest. It's small compared to the others, because I executed it via custom while loops directly from the command line, instead of having the loops in the script. The input where files generated using the previous scripts which where run locally.   

Most of the work in this script is done via axiom's massdns module, resolving large files with generated domains. 

When resolving is ready the result files are cleaned up (while extracting flds' for the next iteration) and the subdomains are send in to securitytrails.

## Tools used
- [Amass](https://github.com/OWASP/Amass)
- [Anew](https://github.com/tomnomnom/anew)
- [Assetfinder](https://github.com/tomnomnom/assetfinder)
- [Axiom](https://github.com/pry0cc/axiom)
- [DNSCewl](https://github.com/codingo/DNSCewl)
- [Massdns](https://github.com/blechschmidt/massdns)
- [ShuffleDNS](https://github.com/projectdiscovery/shuffledns)
- [Subfinder](https://github.com/projectdiscovery/subfinder)


