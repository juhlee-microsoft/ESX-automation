#!/bin/bash
if [ -z $2 ]; then
	echo ERROR -----------------------------------------------------
	echo USAGE: $0 \<IP ADDRESS OF TARGT ESX\> \<VMNIC\>
	echo ERROR -----------------------------------------------------
else
	vmnic=$2
	target=$1
	count=0
	ret=$(ssh $target ethtool -i $vmnic)
	for i in $ret
	do
		if [ $count == 1 ]; then
			echo Driver name is $i
			drvname=$i
		elif [ $count == 3 ]; then
			echo Driver version is $i
			drvver=$i
		elif [ $count == 5 ]; then
			echo Driver FW version is $i
			drvfw=$i
		elif [ $count == 7 ]; then
			echo PCI address is $i
			drvpci=$i
		else
			echo
		fi
	let "count++"
	done

	echo
	echo

	if [ $drvname == $DRIVER ]; then
		echo PASSED: the driver name matched
		echo Expected: $DRIVER
		echo Found: $drvname
	else
		echo FAILED: the driver name expected $DRIVER, but found $drvname
	fi
	echo

	if [ `expr index "$VIB1" "$drvver"` ]; then
		echo PASSED: the driver version matched
		echo Expected: $VIB1
		echo Found: $drvver
	else
		echo FAILED: the driver version expected $VIB1, but found $drvver
	fi
fi
exit
