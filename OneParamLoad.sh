#!/bin/bash
if [ -z $2 ]; then
	echo ERROR -----------------------------------------------------
	echo USAGE: $0 \<IP ADDRESS OF TARGT ESX\> \<VMNIC\>
	echo ERROR -----------------------------------------------------
	exit -1
else
	vmnic=$2
	target=$1
	sleeptime=15

	echo
	echo Target system is $target
	echo
	echo Verifying the VMDQ, LRO, FCOE, RSS and SR-IOV combinational module parameters at the driver loading
	echo

	echo Verify the vmnic is free from vSwitch
	echo
	ret=$(ssh $target esxcfg-vswitch -l | grep $vmnic)

	if [ -n "$ret" ]; then
		echo Found the $vmnic participating in any of vSwitch
		echo Test aborting
		exit -1
	fi

	echo ----------------------------------------------
	echo [Test] Driver loading with a single parameter
	echo ----------------------------------------------
	echo
	echo VMDQ parameter range from 1 to 16
	echo
	for i in 0 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16
	do
		echo ------------
		echo VMDQ = $i
		echo ------------
		echo
		echo Unload ixgbe driver
		ssh $target esxcfg-module -u ixgbe
		echo
		echo Wait $sleeptime seconds
		sleep $sleeptime
		echo
		echo Load ixgbe driver with VMDQ=$i
		ssh $target esxcfg-module ixgbe VMDQ=$i,$i
		echo
		echo Wait $sleeptime seconds
		sleep $sleeptime

		for k in tx rx
		do
			echo
			echo Verify the number of $k queues
			ret=$(ssh $target ethtool -S $vmnic | grep -i queue | grep -i byte | grep -i $k | wc -l)
			echo
			if [ $i == 0 ]; then
				echo Expected the number of queues: 2
			else
				echo Expected the number of queues: $(expr $i + 1)
			fi
			echo
			echo Found the numer of queues: $ret
			echo

			if [[ $ret != $(expr $i + 1) ]]; then
				if [[ ($i == 0) && ($ret == 2) ]]; then
					echo PASSED: Verified $i queues loading successful
				else
					echo FAILED: Failed to load $i queues in the system, found $ret queues
					exit -1
				fi
			else
				echo PASSED: Verified $i queues loading successful
			fi
			echo
			echo ----------------------------
		done
	done

	echo
	echo Resetting the driver load
	ssh $target esxcfg-module -u ixgbe
	sleep #sleeptime

	ssh $target esxcfg-module ixgbe
	sleep $sleeptime

	echo
	echo CNA parameter range from 0 to 1
	echo
	echo Find the system default number of queues
	echo Unload the driver
	ssh $target esxcfg-module -u ixgbe
	echo Wait $sleeptime seconds
	sleep $sleeptime

	echo
	echo Load the driver without parameter
	ssh $target esxcfg-module ixgbe
	echo Wait $sleeptime seconds
	sleep $sleeptime

	echo
	echo Count the number of queues
	txret=$(ssh $target ethtool -S $vmnic | grep -i queue | grep -i byte | grep -i tx | wc -l)
	echo
	echo Found the default VMDQ tx queue size: $txret
	rxret=$(ssh $target ethtool -S $vmnic | grep -i queue | grep -i byte | grep -i rx | wc -l)
	echo
	echo Found the default VMDQ rx queue size: $rxret
	echo

	for i in 0 1
	do
		echo
		echo --------------------
		echo CNA = $i
		echo --------------------
		echo
		echo Unload ixgbe driver
		ssh $target esxcfg-module -u ixgbe
		echo
		echo Wait $sleeptime seconds
		sleep $sleeptime
		echo
		echo Load ixgbe driver with CNA=$i
		ssh $target esxcfg-module ixgbe CNA=$i,$i
		echo
		echo Wait $sleeptime seconds
		sleep $sleeptime

		echo
		echo Verify the number of tx queues
		ret=$(ssh $target ethtool -S $vmnic | grep -i queue | grep -i byte | grep -i tx | wc -l)
		echo

		if [ $i == 0 ]; then
			echo Expected the number of tx queues: $(expr $txret - 1)
			echo Found the numer of tx queues: $ret
			echo
			if [ $(expr $txret - 1) == $ret ]; then
				echo PASSED: Verfied the CNA=$i has $i FCoE queue
			else
				echo FAILED: Failed to find the expected queue size
				exit -1
			fi
		else
			echo Expected the number of tx queues: $txret
			echo Found the numer of tx queues: $ret
			echo
			if [ $txret == $ret ]; then
				echo PASSED: Verified the CNA=$i has $i FCoE queue
			else
				echo FAILED: Failed to find the expected queue size
				exit -1
			fi
		fi

		echo
		echo ----------------------------
	done

	echo
	echo Resetting the driver load
	ssh $target esxcfg-module -u ixgbe
	sleep $sleeptime

	ssh $target esxcfg-module ixgbe
	sleep $sleeptime

	max_vfs=63
	echo
	echo max_vfs parameter range from 0 to $max_vfs
	echo

	i=0

	while [[ $i -lt $max_vfs ]]; do
		let i=i+1
		echo
		echo -------------------
		echo max_vfs = $i
		echo -------------------
		echo
		echo Unload the driver
		ssh $target esxcfg-module -u ixgbe
		echo
		echo Wait $sleeptime seconds
		sleep $sleeptime
		echo

		echo Load the driver with max_vfs=$i with VMDQ=0 and CNA=0
		echo
		ssh $target esxcfg-module ixgbe CNA=0,0 VMDQ=0,0 max_vfs=$i,0
		echo Wait $sleeptime seconds
		sleep $sleeptime
		echo

		ret1=$(ssh $target lspci | grep -i vf | wc -l)
		echo
		echo Found lspci return value $ret1
		ret2=$(ssh $target ethtool -S $vmnic | grep -i vf | grep -i byte | grep -i tx | wc -l)
		echo
		echo Found ethtool tx queue return value $ret2
		ret3=$(ssh $target ethtool -S $vmnic | grep -i vf | grep -i byte | grep -i rx | wc -l)
		echo
		echo Found ethtool rx queue return value $ret3
		echo

		if [[ ($ret1 == $i) && ($ret2 == $i) && ($ret3 == $i) ]]; then
			echo PASSED: Verified all three values matching successfully
		else
			echo FAILED: Could not match any of them or all
			exit -1
		fi
		echo
	done

	echo
	echo RSS parameter range from 0 to 1
	echo

	echo
	echo ---------------------
	echo RSS = 0
	echo ---------------------

	i=0
	echo
	echo Find the system default number of queues
	echo Unload the driver
	ssh $target esxcfg-module -u ixgbe
	echo Wait $sleeptime seconds
	sleep $sleeptime

	echo
	echo Load the driver without CNA and RSS. Obtain the VMDQ queue size only.
	ssh $target esxcfg-module ixgbe CNA=0,0 RSS=0,0
	echo Wait $sleeptime seconds
	sleep $sleeptime

	echo Count the number of queues
	txret=$(ssh $target ethtool -S $vmnic | grep -i queue | grep -i byte | grep -i tx | wc -l)
	echo Found the default VMDQ tx queue size: $txret
	rxret=$(ssh $target ethtool -S $vmnic | grep -i queue | grep -i byte | grep -i rx | wc -l)
	echo Found the default VMDQ rx queue size: $rxret
	echo

	echo
	echo Unload the driver
	ssh $target esxcfg-module -u ixgbe
	echo Wait $sleeptime seconds
	sleep $sleeptime
	echo

	echo --------------------------------------
	echo Load the driver with RSS=1 with CNA=0
	echo --------------------------------------
	echo

	ssh $target esxcfg-module ixgbe CNA=0,0 RSS=1,1
	echo Wait $sleeptime seconds
	sleep $sleeptime
	echo

	echo
	echo Query the number of queues with RSS
	echo Expect tx queue size: $txret + 1
	echo Expect rx queue size: $rxret + 4
	echo
	txret2=$(ssh $target ethtool -S $vmnic | grep -i queue | grep -i byte | grep -i tx | wc -l)
	echo Found the tx queue size: $txret2
	rxret2=$(ssh $target ethtool -S $vmnic | grep -i queue | grep -i byte | grep -i rx | wc -l)
	echo Found the rx queue size: $rxret2
	echo

	if [[ ($(expr $txret + 1) == $txret2) && ($(expr $rxret + 4) == $rxret2) ]]; then
		echo PASSED: Verified RSS increased 1 more tx queue and 4 more rx queue
	else
		echo FAILED: Could not find the correct number of RSS queues.
		exit -1
	fi

	echo
	echo LRO parameter range from 0 to 1
	echo

	echo --------------
	echo LRO = 0
	echo --------------
	echo
	echo Unloading the driver
	ssh $target esxcfg-module -u ixgbe
	echo Wait $sleeptime seconds
	sleep $sleeptime

	echo Loading the driver with LRO=0
	ssh $target esxcfg-module ixgbe LRO=0,0
	echo Wait $sleeptime seconds
	sleep $sleeptime

	sleep $sleeptime
	ret=$(ssh $target tail -300 /var/log/vmkernel.log | grep ixgbe | grep -i LRO)
	echo

	echo Expected to find "LRO ... Disabled" in the vmkernel log
	echo
	echo Return value: $ret
	echo

	if [[ ("$ret" =~ "LRO") && ("$ret" =~ "Disabled") ]]; then
		echo PASSED: Found below log in vmkernel log
	else
		echo FAILED: Could not verify the LRO disabled
		#exit -1
	fi
	echo

	echo
	echo --------------
	echo LRO = 1
	echo --------------
	echo

	echo Unloading the driver
	ssh $target esxcfg-module -u ixgbe
	echo Wait $sleeptime seconds
	sleep $sleeptime

	echo Loading the driver with LRO=1
	ssh $target esxcfg-module ixgbe LRO=1,1
	echo Wait $sleeptime seconds
	sleep $sleeptime

	ret=$(ssh $target tail -300 /var/log/vmkernel.log | grep ixgbe | grep -i LRO)
	echo Expected to find "LRO ... Enabled" in the vmkernel log
	echo

	if [[ ("$ret" =~ "LRO") && ("$ret" =~ "Enabled") ]]; then
		echo PASSED: Found below log in vmkernel log
	else
		echo FAILED: Could not verify the LRO enabled
		#exit -1
	fi

	echo $ret
	echo

fi
exit
