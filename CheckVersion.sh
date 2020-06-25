if [ -z $1 ]
then
	echo ERROR --------------------------------
	echo USAGE: $0 \<IP ADDRESS OF TARGET ESX\>
	echo ERROR --------------------------------
else
	target=$1
	ssh $target vmware -v
fi
