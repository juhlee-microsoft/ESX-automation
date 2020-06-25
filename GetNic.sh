#!/bin/sh
#################################################
#### Filename: GetNic.sh
#### Description: Get the vmnic per input driver
####   name, and display the version.
#################################################
if [ -z $2 ]
then
	echo $(date) ERROR ------------------------------
	echo $(date) USAGE: $0 \<IP ADDRESS OF TARGET ESX\> \<DRIVER NAME\>
	echo $(date) ERROR ------------------------------
else
	target=$1
	drivername=$2
	vmnics=$(ssh $target esxcli network nic list | grep $drivername | cut -c1-7)
	for i in $vmnics
	do
		echo
		echo \[$i\]
		version=$(ssh $target ethtool -i $i | grep -i version)
		#fwversion=$(ssh $target ethtool -i $i | grep -i firmware)
		pcislot=$(ssh $target ethtool -i $i | grep -i bus-info)
		echo $version
		#echo $fwversion
		filter=$(echo $pcislot | cut -c15-20)
		ssh $target lspci -nv | grep $filter | grep $i
		echo ----------------------------------------------------------
	done
fi
