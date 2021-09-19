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
