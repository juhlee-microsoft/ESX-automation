#!/bin/bash
if [ -z $2 ]; then
	echo ERROR -----------------------------------------------------
	echo USAGE: $0 \<IP ADDRESS OF TARGT ESX\> \<VMNIC\>
	echo ERROR -----------------------------------------------------
else
	vmnic=$2
	target=$1

	echo
	echo Target system is $target
	echo
	echo Verifying the head of family product device ID in XML file
	echo

	for i in 10fb 1528
    do
		ret=$(ssh $target cat /etc/vmware/driver.map.d/ixgbe.map | grep -i $i)
		if [[ -n $ret ]]; then
			echo Passed: Device ID $i is included in the PCI XML file
			echo Expected: $i
			echo Found: $ret
			echo
		else
			echo Failed: Found none device ID information in PCI XML file
			echo Expected: $i
			echo Found: $ret
			echo List out the whole XML contents below.
			ssh $target cat /etc/vmware/driver.map.d/ixgbe.map
			echo
		fi
	done
fi
exit
