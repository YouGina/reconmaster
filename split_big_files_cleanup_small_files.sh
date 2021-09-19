grep -Hrni "no target" | awk -F':' '{print $1}' | while read f; do
	rm $f;
done


find . -size +100M | while read f; do
	split -b 100M $f ./${f}_split; rm $f;
done

