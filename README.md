# SecurityTrails x Amass ReconMaster contest

In this little write-up I'll try to explain shortly what I did to be able to get to the ninth place of the SecurityTrails ReconMaster contest.

Throughouth the contest I tried to keep it as simple as possible.

* Find subdomains for not too well-known domains (using assetfinder)
* Extract words from the discovered subdomains (split by dots and dashes; using a custom script)
* Generate permutations based on the found words (using DNSCewl and custom scripts)
* Resolve the generated permutations to either A or CNAME records (using massdns)

My biggest challenge was the lack of memory and storage space required to generate the permutations. This I solved by splitting big files into smaller chunks and and run it in batches. To manage this I created a bunch of custom scripts as well.

As this was a contest for SeucrityTrails x Amass I did keep one thread of amass running. This was going over a list of 2 letter domains using the custom wordlist I generated. This wordlist kept growing while the steps described earlier iterated.

## Tools used
- [Amass](https://github.com/OWASP/Amass)
- [Anew](https://github.com/tomnomnom/anew)
- [Assetfinder](https://github.com/tomnomnom/assetfinder)
- [Axiom](https://github.com/pry0cc/axiom)
- [DNSCewl](https://github.com/codingo/DNSCewl)
- [Massdns](https://github.com/blechschmidt/massdns)
- [ShuffleDNS](https://github.com/projectdiscovery/shuffledns)
- [Subfinder](https://github.com/projectdiscovery/subfinder)


