#!/bin/bash
echo
echo Capture vmkernel file from core dump such as PSOD case
echo
if [ -z $1 ]; then
	echo
	echo USAGE: $0 \<IP ADDRESS OF ESX\>
	echo
else
	export target=$1
	ssh $target esxcfg-dumppart -l
	echo Enter directory path for dump
	echo TIP: it is under Console section
	read x
	ret=$(ssh $target esxcfg-dumppart -C -D $x)
	if [[ "$ret" =~ "Error" ]]; then
		echo Enter directory of vmkernel-zdump file
		read x
		ssh $target esxcfg-dumppart -L $x
	else
		echo ERROR could not find dump partition.
		echo Abort the operation, please check out the vmkernel dump file
	fi
fi

