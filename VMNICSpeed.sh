#!/bin/bash
if [ -z $2 ]; then
	echo ERROR -----------------------------------------------------
	echo USAGE: $0 \<IP ADDRESS OF TARGT ESX\> \<VMNIC\>
	echo ERROR -----------------------------------------------------
else
	vmnic=$2
	target=$1

	if [[ $(ssh $target esxcfg-nics -l | grep $vmnic | cut -c40-48) == "10000Mbps" ]]; then
		echo Passed: It shows the correct speed information in the system
		ssh $target esxcfg-nics -l | grep $vmnic | cut -c40-48
		echo
		if [[ $(ssh $target esxcfg-nics -l | grep $vmnic | cut -c50-54) =~ "Full" ]]; then
			echo Passed: It shows the correct duplex information in the system
			ssh $target esxcfg-nics -l | grep $vmnic | cut -c50-54
		else
			echo Failed : Found incorrect duplex information
			ssh $target esxcfg-nics -l | grep $vmnic | cut -c50-54
			exit
		fi
	else
		echo Failed: Found incorrect speed information
		ssh $target esxcfg-nics -l | grep $vmnic | cut -c40-48
		echo
		#exit
	fi
fi
exit
