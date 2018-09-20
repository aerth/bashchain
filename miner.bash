# miner.bash
# aerth
# generates nonces, hashes

# get HASHER, DIFFICULTY, getparenthash
source hashchain.bash

nonce=$(( ( RANDOM ) ))
fps=$((0))
last=$(($(date +%s)))
now=$(date +%s)

# print to stderr, we are sending stdout to hashchain.bash
log(){
	printf "MINER: $@\n" 1>&2
}

# loop
while true; do
	# read chain or start from genesis	
	parenthash=$(getparenthash)
	
	# fill "block" with contents
	contents="none"

	# update timestamp
	now=$(date +%s)
	
	# print new work
	echo 1>&2
	log "begin new work: $parenthash$now$nonce$contents"
	echo 1>&2

	# mine
	while true; do
		# increment nonce
		((++nonce))
		# optionally, increase timestamp if all nonces are tried
		test $nonce -eq 0 && \
			log "tried all nonces, bumping timestamp" && \
			now=$(date +%s)

		# this is what gets hashed
		# (all header fields, and contents)
		seedhash="$parenthash""$now""$nonce""$contents"
		
		# do the work
		hash=$(printf $seedhash| $HASHER | awk '{print $1}')


		# increase fps
		((++fps))
		fpsnow=$(date +%s)
		# show fps every 10 seconds (diving fps by 10)
		if [ $fpsnow != $last ] && [ "0" == "$(($fpsnow % 10))" ]; then
			log "h/s: $(($fps/10)) nonce=$nonce seed=$seedhash"
			((fps=0))
			last=$fpsnow
		fi

		# check difficulty (number of zeros)
		check2=${hash#$DIFFICULTY}
		if [ $check2 == $hash ]; then
			continue
		fi	
		
		# success
		log "mined: ($hash) parent=$parenthash timestamp=$now nonce=$nonce contents=$contents\n" 1>&2

		# send to pipeline
		echo $parenthash $now $nonce $contents
	
		
		# allow chain to update
		sleep 0.3
	
		# get new work
		break 
	done

done
