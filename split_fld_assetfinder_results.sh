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

