#!/bin/sh
if [ -z $2 ]; then
	echo ERROR ------------------------------------------
	echo USAGE: $0 \<IP ADDRESS OF ESX\> \<vSwitch NAME\>
	echo ERROR ------------------------------------------
	echo
else
	export target=$1
	export vsw=$2

	existing=$(ssh $target esxcfg-vswitch -c $vsw)
	if [ $existing -eq "1" ]; then
		echo Deleting vSwitch $vsw in ESX $target
		ssh $target esxcfg-vswitch -d $vsw
		sleep 1
		existing=$(ssh $target esxcfg-vswitch -c $vsw)
		if [ $existing -eq "1" ]; then
			echo ERROR Still found vSwitch $vsw in ESX $target
			echo Please check out vmkernel log
		else
			echo Successfully deleted vSwitch $vsw in ESX $target
		fi
	else
		echo ERROR Can not find the vSwitch $vsw in ESX $target
		echo Please check out the system first
	fi
fi
