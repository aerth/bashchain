# hashchain.bash
# aerth
# reads stdin for new proof of work
# validates, adds to chain.db

# choose difficulty
DIFFICULTY="000" # add more zeros ("00") for more difficulty

# choose hasher
#HASHER="md5sum"
HASHER="sha256sum"
#HASHER="sha384sum"
#HASHER="shasum"

# produces genesis hash
GENESIS_CONTENTS="0000000000000000000000000000000"

log(){
	echo "CHAIN: $@" 1>&2
}

getparenthash(){
	touch chain.db
	exec 5< chain.db
	while read p_parent <&5; do
		read p_time <&5
		read p_nonce <&5
		read p_contents <&5
		read p_blank <&5
	p="$p_parent""$p_time""$p_nonce""$p_contents"
	done
	test -z "$p" && \
		log "New genesis" && \
		p=$GENESIS_CONTENTS
	
	printf "$p" | $HASHER | awk '{print $1}'
}

insert() {
	printf "$1\n$2\n$3\n$4\n\n" >> chain.db
	echo 1>&2		
	echo 1>&2		
	log "## received ##"
	log "hash: 0x   $5"
	log "parent:    $1"
	log "timestamp: $2"
	log "nonce:     $3"
	exit 0;

}
validate(){
	# usage:
	# validate <parenthash> <timestamp> <nonce> <contents>
	test -z "$1" && log "empty 1" && exit 111
	test -z "$2" && log "empty 2" && exit 111
	test -z "$3" && log "empty 3" && exit 111
	test -z "$4" && log "empty 4" && exit 111	
	
	log "validating parenthash"
	# validate parent
	parenthash=$(getparenthash)
	test "$parenthash" == "$1" || (log "invalid parenthash, wanted $parenthash" && exit 111)
	
	log "validating timestamp"
	# validate timestamp
	now=$(date +%s)
	test "$now -ge $2" || (log "invalid timestamp" && exit 111)

	log "validating proof-of-work"
	# validate hash
	
	check=$(printf "$1$2$3$4" | $HASHER | awk '{print $1}')
	check2=${check#$DIFFICULTY}
	test "$check2" != "$check" || (log "bad difficulty: $check" && exit 111)
	log "valid: $check"
	insert $1 $2 $3 $4 $check
}

genesisblock(){
	printf "$GENESISCONTENTS" | $HASHER | awk '{print $1}'
}

importchain(){
	if [ ! -s chain.db ]; then
		echo " no chain "
		exit 0
	fi
	num=$((0))
	touch chain.db
	exec 5< chain.db
	hash=$(genesisblock)
	first=""
	while read p_parent <&5 ; do
		read p_time <&5
		read p_nonce <&5
		read p_contents <&5
		read p_blank <&5
		p="$p_parent$p_time$p_nonce$p_contents"
		test -z "$p_blank" || (log "invalid chain.db" && exit 111)

		test -z "$first" || (test "$hash" == "$p_parent" || ( log "invalid parent, wanted $hash, got $p_parent" && continue))
		first=$hash
		
		hash=$(printf "$p" | $HASHER | awk '{print $1}')
		check2=${hash#$DIFFICULTY}
		if [ $check2 == $hash ]; then
			log "bad difficulty: $hash"
		else	
			log "imported $num: hash=$hash nonce=$p_nonce" 
			printf "$p_parent\n$p_time\n$p_nonce\n$p_contents\n\n" >> chain.db2
			((++num))	
		fi
	done
	test -s chain.db2 && \
	mv chain.db chain.db.backup && \
	mv chain.db2 chain.db && \
	log "reindexed chain.db"
}

doit(){

	echo $(importchain || echo "new chain")
log "listening on port BASH"

while read incoming; do
	log "RECV: $incoming"
	(validate $incoming && \
		log "inserted") || \
		log "denied"

done
}

importchainloop(){
	while true; do
		importchain
		sleep 10
	done
}

doit2(){
	importchainloop &
	doit
}

if [ "$0" = "./hashchain.bash" ]; then
	if [ "$1" == "reindex" ]; then
		importchain
	elif [ "$1" == "run" ]; then
		doit
	else
		echo "$0 run (or: ./miner.bash | $0 [run|reindex])" && exit 111
	fi
fi
