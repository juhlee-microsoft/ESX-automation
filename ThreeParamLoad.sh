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
	echo [Test] Driver loading with three parameters
	echo ----------------------------------------------
	echo

	echo max_vfs + VMDQ + CNA
	echo max_vfs + VMDQ + RSS
	echo max_vfs + VMDQ + LRO
	echo max_vfs + CNA + RSS
	echo max_vfs + CNA + LRO
	echo max_vfs + RSS + LRO

	max_vfs=63
	echo
	echo max_vfs parameter range from 0 to $max_vfs
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
	txdfret=$(ssh $target ethtool -S $vmnic | grep -i queue | grep -i byte | grep -i tx | wc -l)
	echo
	echo Found the default VMDQ tx queue size: $txdfret
	rxdfret=$(ssh $target ethtool -S $vmnic | grep -i queue | grep -i byte | grep -i rx | wc -l)
	echo
	echo Found the default VMDQ rx queue size: $rxdfret
	echo

	i=0

	while [[ $i -lt $max_vfs ]]; do
		let i=i+1
		for vmdq in 0 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16
		do
			for cna in 0 1
			do

				echo
				echo -------------------------------
				echo max_vfs=$i VMDQ=$vmdq CNA=$cna
				echo -------------------------------
				echo

				echo Unload the driver
				ssh $target esxcfg-module -u ixgbe
				echo
				echo Wait $sleeptime seconds
				sleep $sleeptime
				echo

				echo Load the driver with max_vfs=$i VMDQ=$vmdq CNA=$cna
				echo
				ssh $target esxcfg-module ixgbe CNA=$cna,$cna,$cna,$cna VMDQ=$vmdq,$vmdq,$vmdq,$vmdq max_vfs=$i,0,0,0
				echo Wait $sleeptime seconds
				sleep $sleeptime
				echo

				echo Expected the number of VF: $i

				ret1=$(ssh $target lspci | grep -i vf | wc -l)
				echo
				echo Found lspci VF return value $ret1
				ret2=$(ssh $target ethtool -S $vmnic | grep -i vf | grep -i byte | grep -i tx | wc -l)
				echo
				echo Found ethtool tx VF return value $ret2
				ret3=$(ssh $target ethtool -S $vmnic | grep -i vf | grep -i byte | grep -i rx | wc -l)
				echo
				echo Found ethtool rx VF return value $ret3
				echo

				if [[ ($ret1 == $i) && ($ret2 == $i) && ($ret3 == $i) ]]; then
					echo PASSED: Verified all three values matching successfully
				else
					echo FAILED: Could not match any of them or all
					#exit -1
				fi

				for k in tx rx
				do
					echo
					if [ $vmdq == 0 ]; then
						echo Expected the number of queues: 2
					else
						echo Expected the number of queues: $(expr $vmdq + 1)
					fi

					echo
					echo Verify the number of $k queues
					ret=$(ssh $target ethtool -S $vmnic | grep -i queue | grep -i byte | grep -i $k | wc -l)
					echo
					echo Found the numer of queues: $ret
					echo

					if [[ $ret != $(expr $vmdq + 1) ]]; then
						if [[ ($vmdq == 0) && ($ret == 2) ]]; then
							echo PASSED: Verified $vmdq queues loading successful
						else
							echo FAILED: Failed to load $vmdq queues in the system, found $ret queues
							#exit -1
						fi
					else
						echo PASSED: Verified $vmdq queues loading successful
					fi
					echo
			done
			echo
			echo
			echo Verify the number of tx queues
			ret=$(ssh $target ethtool -S $vmnic | grep -i queue | grep -i byte | grep -i tx | wc -l)
			echo

			if [ $cna == 0 ]; then
				if [ $vmdq == 0 ]; then
					echo Expected the number of tx queues: $(expr $vmdq + 1)
					echo Found the numer of tx queues: $ret
					echo
					if [ $(expr $vmdq + 1) == $ret ]; then
						echo PASSED: Verfied the CNA=$cna has $cna FCoE queue
					else
						echo FAILED: Failed to find the expected queue size
						#exit -1
					fi
				else
					echo Expected the number of tx queues: $vmdq
					echo Found the numer of tx queues: $ret
					echo
					if [ $vmdq == $ret ]; then
						echo PASSED: Verfied the CNA=$cna has $cna FCoE queue
					else
						echo FAILED: Failed to find the expected queue size
						#exit -1
					fi
				fi
			else
				if [ $vmdq == 0 ]; then
					echo Expected the number of tx queues: $(expr $vmdq + 2)
					echo Found the numer of tx queues: $ret
					echo
					if [ $(expr $vmdq + 2) == $ret ]; then
						echo PASSED: Verified the CNA=$cna has $cna FCoE queue
					else
						echo FAILED: Failed to find the expected queue size
						#exit -1
					fi
				else
					echo Expected the number of tx queues: $(expr $vmdq + 1)
					echo Found the numer of tx queues: $ret
					echo
					if [ $(expr $vmdq + 1) == $ret ]; then
						echo PASSED: Verified the CNA=$cna has $cna FCoE queue
					else
						echo FAILED: Failed to find the expected queue size
						#exit -1
					fi
				fi
			fi
			echo
		done
		echo
		echo -----------------------------------
		echo max_vfs=$i VMDQ=$vmdq RSS=0 CNA=0
		echo -----------------------------------
		echo

		echo Find the system default number of queues
		echo Unload the driver
		ssh $target esxcfg-module -u ixgbe
		echo Wait $sleeptime seconds
		sleep $sleeptime

		echo
		echo Load the driver without CNA and RSS. Obtain the VMDQ queue size only.
		ssh $target esxcfg-module ixgbe max_vfs=$i,0 VMDQ=$vmdq,$vmdq CNA=0,0 RSS=0,0
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

		echo -----------------------------------
		echo max_vfs=$i VMDQ=$vmdq RSS=1 CNA=0
		echo -----------------------------------
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
			#exit -1
		fi

	done

done

echo VMDQ + CNA + RSS
echo VMDQ + CNA + LRO

echo CNA + RSS + LRO
fi
exit
