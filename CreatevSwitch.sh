#!/bin/sh
if [ -z $4 ]; then
	echo ERROR ----------------------------------------------------------------------------
	echo USAGE: $0 \<IP ADDRESS OF ESX\> \<vSwitch NAME\> \<Portgroup NAME\> \<vmnic\>
	echo ERROR ----------------------------------------------------------------------------
	echo
else
	export target=$1
	export vsw=$2
	export pg=$3
	export vmnic=$4

	existing=$(ssh $target esxcfg-vswitch -c $vsw)
	if [ $existing -eq "1" ]; then
		echo ERROR -----
		echo Please check out vSwitch name if already exists
	else
		echo Creating vSwitch $vsw
		ssh $target esxcfg-vswitch -a $vsw
		sleep 1
		echo Adding portgroup $pg
		ssh $target esxcfg-vswitch -A $pg $vsw
		sleep 1
		echo Uplinking vmnic$vmnic
		ssh $target esxcfg-vswitch -L $vmnic $vsw
		sleep 1
		ssh $target esxcfg-vswitch -l
		sleep 1
	fi
	echo Successfully created a vSwitch $vsw
fi
