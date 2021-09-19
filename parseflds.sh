input=$1;
d=$(dig +nocmd $input any +short);

if [[ $d ]]; then
	echo $input
fi

