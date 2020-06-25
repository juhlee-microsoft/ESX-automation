#!/bin/bash
if [ -z $2 ]; then
		echo ERROR -----------------------------------------------------
		echo USAGE: $0 \<IP ADDRESS OF TARGT ESX\> \<VMNIC #\>
		echo ERROR -----------------------------------------------------
else
	target=$1
	vmnic=$2

	ssh $target vsish -e get /net/pNics/vmnic$vmnic/rxqueues/queues/0/info | grep active
	for i in 0 1 2 3 4 5 6 7
	do
		ssh $target vsish -e get /net/pNics/vmnic$vmnic/rxqueues/queues/0/filters/$i/filter | grep unicastAddr
		ssh $target vsish -e get /net/pNics/vmnic$vmnic/rxqueues/queues/0/filters/$i/filter | grep load
		echo
	done
fi
