if [ -z $2 ];
then
	echo ERROR -----
	echo Please use $0 \<IP ADDRESS OF TARGET ESX\> \<TEST SCRIPT\>
else
	if [ -e $2 ] && [ -x $2 ];
	then
		scp $2 root@$1:/tmp
		ssh $1 /tmp/$2 2>&1
		ssh $1 rm /tmp/$2
	else
		echo ERROR -----
		echo Please check out your test script $2 if it is available
	fi
fi
exit
