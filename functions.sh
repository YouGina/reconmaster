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
	DNScewl --target-list=$domain --append-list=../../../lists/vhosts.txt > dnscewl/$domain
	masscheckandsend dnscewl/$domain
	DNScewl --target-list=$domain --prepend-list=../../../lists/vhosts.txt > dnscewl/$domain
	masscheckandsend dnscewl/$domain
	DNScewl --target-list=$domain --set-list=../../../lists/vhosts.txt > dnscewl/$domain	
	masscheckandsend dnscewl/$domain
	DNScewl --target-list=$domain --set-list=words > dnscewl/$domain
	masscheckandsend dnscewl/$domain

	rm dnscewl/$domain
	rm assets_new
}
