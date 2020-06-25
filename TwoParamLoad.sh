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

	echo
	echo ----------------------------------------------
	echo [Test] Driver loading with 2 parameters
	echo ----------------------------------------------
	echo

	echo
	echo max_vfs parameter range from 0 to 63 with LRO, VMDQ, RSS, and CNA
	echo

	max_vfs=63

	i=0
	echo
	echo Max max_vfs value is $max_vfs

	while [[ $i -lt $max_vfs ]]; do
		let i=i+1
		echo
		echo Unload the driver
		ssh $target esxcfg-module -u ixgbe
		echo Wait $sleeptime seconds
		sleep $sleeptime
		echo

#LRO test with SR-IOV
		echo -----------------------------
		echo max_vfs + LRO
		echo -----------------------------
		echo
		echo Load the driver with max_vfs=$i LRO=1 
		ssh $target esxcfg-module ixgbe max_vfs=$i,0 LRO=1,0
		echo Wait $sleeptime seconds
		sleep $sleeptime
		echo

		echo Wait $sleeptime to reset the system
		sleep $sleeptime

#vmkernel log requires more time to writing logs

		ret=$(ssh $target tail -200 /var/log/vmkernel.log | grep ixgbe | grep -i LRO)
		echo Expected to find "LRO ... Enabled" in the vmkernel log
		echo

		ret1=$(ssh $target lspci | grep -i vf | wc -l)
		echo
		echo Found lspci return value $ret1
		ret2=$(ssh $target ethtool -S $vmnic | grep -i vf | grep -i byte | grep -i tx | wc -l)
		echo Found ethtool tx queue return value $ret2
		ret3=$(ssh $target ethtool -S $vmnic | grep -i vf | grep -i byte | grep -i rx | wc -l)
		echo Found ethtool rx queue return value $ret3
		echo 

		if [[ ("$ret" =~ "LRO") && ("$ret" =~ "Enabled") ]]; then
			echo PASSED: Found below log in vmkernel log
			echo $ret
			echo

			if [[ ($ret1 == $i) && ($ret2 == $i) && ($ret3 == $i) ]]; then
				echo PASSED: Verified all three values of VF matching successfully
			else
				echo FAILED: Could not match any of them or all
				#exit -1
			fi
			echo
		else
			echo FAILED: Could not verify the LRO enabled
			echo $ret
			#exit -1
		fi

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
			#exit -1
		fi
		echo
		echo
		echo

		echo Wait $sleeptime to reset the system
		sleep $sleeptime

#VMDQ test with SR-IOV

		echo -----------------------------
		echo max_vfs + VMDQ
		echo -----------------------------
		echo
		for x in 0 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16
		do
			echo
			echo Unload ixgbe driver
			ssh $target esxcfg-module -u ixgbe
			echo
			echo Wait $sleeptime seconds
			sleep $sleeptime
			echo
			echo Load ixgbe driver with max_vfs=$i VMDQ=$x
			ssh $target esxcfg-module ixgbe VMDQ=$x,0 max_vfs=$i,0
			echo
			echo Wait $sleeptime seconds
			sleep $sleeptime

			for k in tx rx
			do
				echo
				echo Verify the number of $k queues
				ret=$(ssh $target ethtool -S $vmnic | grep -i queue | grep -i byte | grep -i $k | wc -l)
				echo

				if [ $x == 0 ]; then
					echo Expected the number of queues: 1
				else
					echo Expected the number of queues: $x
				fi
				echo Found the numer of $k queues: $ret
				echo

				if [[ $ret != $x ]]; then
					if [[ ($x == 0) && ($ret == 1) ]]; then
						echo PASSED: Verified $ret queues loading successful
					else
						echo FAILED: Failed to load $x queues in the system, but found $ret queues
						#exit -1
					fi
				else
					echo PASSED: Verified $x queues loading successful
				fi

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
					#exit -1
				fi

				echo
			done
		done

#RSS test with SR-IOV

		echo
		echo -----------------------------
		echo max_vfs + RSS 
		echo -----------------------------

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

		echo Load the driver with RSS=1 max_vfs=$i

		ssh $target esxcfg-module ixgbe CNA=0,0 RSS=1,1 max_vfs=$i,0
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
			#exit -1
		fi
		echo

#CNA test with SR-IOV

		echo -----------------------------
		echo max_vfs + CNA
		echo -----------------------------
		echo
		echo Find the system default number of queues
		echo Unload the driver
		echo
		ssh $target esxcfg-module -u ixgbe
		echo Wait $sleeptime seconds
		sleep $sleeptime

		echo
		echo Load the driver without parameter
		ssh $target esxcfg-module ixgbe
		echo Wait $sleeptime seconds
		sleep $sleeptime

		echo Count the number of queues
		txret=$(ssh $target ethtool -S $vmnic | grep -i queue | grep -i byte | grep -i tx | wc -l)
		echo Found the default VMDQ tx queue size: $txret
		rxret=$(ssh $target ethtool -S $vmnic | grep -i queue | grep -i byte | grep -i rx | wc -l)
		echo Found the default VMDQ rx queue size: $rxret
		echo

# SR-IOV and RSS enable turns off CNA by default

		for i in 0
		do
			echo
			echo CNA = $i
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
					#exit -1
				fi
			else
				echo Expected the number of tx queues: $txret
				echo Found the numer of tx queues: $ret
				echo
				if [ $txret == $ret ]; then
					echo PASSED: Verified the CNA=$i has $i FCoE queue
				else
					echo FAILED: Failed to find the expected queue size
					#exit -1
				fi
			fi

			if [ $i == 0 ]; then
				echo Expected the number of rx queues: $(expr $rxret - 1)
				echo Found the numer of rx queues: $ret
				echo
				if [ $(expr $rxret - 1) == $ret ]; then
					echo PASSED: Verfied the CNA=$i has $i FCoE queue
				else
					echo FAILED: Failed to find the expected queue size
					#exit -1
				find
			else
				echo Expected the number of rx queues: $rxret
				echo Found the numer of rx queues: $ret
				echo
				if [ $rxret == $ret ]; then
					echo PASSED: Verfied the CNA=$i has $i FCoE queue
				else
					echo FAILED: Failed to find the expected queue size
					#exit -1
				fi
			fi

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
				#exit -1
			fi
			echo

		done

	done

#LRO: VMDQ, RSS and CNA
	echo
	echo LRO parameter range from 0 to 1 with VMDQ, RSS, and CNA
	echo

	echo ----------------------------
	echo LRO + VMDQ
	echo -----------------------------
	echo

	for lro in 0 1
	do
		for vmdq in 0 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16
		do
			echo
			echo LRO = $lro
			echo VMDQ = $vmdq
			echo
			echo Unload the driver
			ssh $target esxcfg-module -u ixgbe
			echo
			echo Wait $sleeptime seconds
			sleep $sleeptime

			echo Load the driver with LRO=$lro VMDQ=$vmdq
			ssh $target esxcfg-module ixgbe LRO=$lro,$lro VMDQ=$vmdq,$vmdq
			echo Wait $sleeptime seconds
			sleep $sleeptime
			echo

			echo Wait $sleeptime to reset the system
			sleep $sleeptime

#vmkernel log requires more time to writing logs

			ret=$(ssh $target tail -200 /var/log/vmkernel.log | grep ixgbe | grep -i LRO)
			echo Expected to find "LRO ... Enabled" in the vmkernel log
			echo

			if [[ ("$ret" =~ "LRO") && ("$ret" =~ "Enabled") ]]; then
				echo PASSED: Found below log in vmkernel log
				echo $ret
				echo
			else
				echo FAILED: Could not verify the LRO enabled
				echo $ret
				#exit -1
			fi

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
						#exit -1
					fi
				else
					echo PASSED: Verified $i queues loading successful
				fi
				echo
			done
		done
	done


	#VMDQ: RSS and CNA

	echo ----------------------------
	echo VMDQ + RSS
	echo -----------------------------
	echo

	echo VMDQ parameter range from 1 to 16
	echo

	for i in 0 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16
	do
		for rss in 0 1
		do

			echo -----------------
			echo VMDQ=$i RSS=$rss
			echo -----------------
			echo
			echo Unload ixgbe driver
			ssh $target esxcfg-module -u ixgbe
			echo
			echo Wait $sleeptime seconds
			sleep $sleeptime
			echo
			echo Load ixgbe driver with VMDQ=$i RSS=$rss
			if [ $rss == 1 ]; then
				ssh $target esxcfg-module ixgbe VMDQ=$i,$i RSS=$rss,$rss CNA=0,0
				echo CNA disabled because RSS enabled
			else
				ssh $target esxcfg-module ixgbe VMDQ=$i,$i RSS=$rss,$rss
			fi

#CNA should be disabled because RSS enabled

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
						#exit -1
					fi
				else
					echo PASSED: Verified $i queues loading successful
				fi
				echo
			done
# add RSS verification
			if [ $rss == 0 ]; then
				echo Count the number of queues
				txret=$(ssh $target ethtool -S $vmnic | grep -i queue | grep -i byte | grep -i tx | wc -l)
				echo Found the default VMDQ tx queue size: $txret
				rxret=$(ssh $target ethtool -S $vmnic | grep -i queue | grep -i byte | grep -i rx | wc -l)
				echo Found the default VMDQ rx queue size: $rxret
				echo
			else
				echo
				txret2=$(ssh $target ethtool -S $vmnic | grep -i queue | grep -i byte | grep -i tx | wc -l)
				echo Found the tx queue size: $txret2
				rxret2=$(ssh $target ethtool -S $vmnic | grep -i queue | grep -i byte | grep -i rx | wc -l)
				echo Found the rx queue size: $rxret2
				echo
			fi
		done

		if [[ ($(expr $txret + 1) == $txret2) && ($(expr $rxret + 4) == $rxret2) ]]; then
			echo PASSED: Verified RSS increased 1 more tx queue and 4 more rx queue
		else
			echo FAILED: Could not find the correct number of RSS queues.
			#exit -1
		fi

	done


	echo ----------------------------
	echo VMDQ + CNA
	echo -----------------------------
	echo

	echo VMDQ parameter range from 1 to 16
	echo
	for vmdq in 0 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16
	do
		for cna in 0 1
		do

			echo -----------------
			echo VMDQ=$vmdq CNA=$cna
			echo -----------------
			echo
			echo Unload ixgbe driver
			ssh $target esxcfg-module -u ixgbe
			echo
			echo Wait $sleeptime seconds
			sleep $sleeptime
			echo
			echo Load ixgbe driver with VMDQ=$i
			ssh $target esxcfg-module ixgbe VMDQ=$vmdq,$vmdq CNA=$cna,$cna
			echo
			echo Wait $sleeptime seconds
			sleep $sleeptime

			for k in tx rx
			do
				echo
				echo Verify the number of $k queues
				ret=$(ssh $target ethtool -S $vmnic | grep -i queue | grep -i byte | grep -i $k | wc -l)
				echo
				echo Found the numer of queues: $ret
				echo

				if [ $vmdq == 0 ]; then
					if [ $cna == 0 ]; then
						echo Expected the number of queues: 1
						if [ $ret == 1 ]; then
							echo PASSED: Found $ret queue successfully
						else
							echo FAILED: Found $ret queues. Please reproduce in the system
							echo VMDQ=$vmdq CNA=$cna
							#exit -1
						fi
					else
						echo Expected the number of queues: 2
						if [ $ret == 2 ]; then
							echo PASSED: Found $ret queues successfully
						else
							echo FAILED: Found $ret queues. Please reproduce in the system
							echo VMDQ=$vmdq CNA=$cna
							#exit -1
						fi
					fi
				else
					if [ $cna == 0 ]; then
							echo Expected the number of queues: $vmdq
						if [ $ret == $vmdq ]; then
							echo PASSED: Found $ret queues successfully
						else
							echo FAILED: Found $ret queues. Please reproduce in the system
							echo VMDQ=$vmdq CNA=$cna
							#exit -1
						fi
					else
						echo Expected the number of queues: $(expr $vmdq + 1)
						if [ $ret == $(expr $vmdq + 1) ]; then
							echo PASSED: Found $ret queues successfully
						else
							echo FAILED: Found $ret queues. Please reproduce in the system
							echo VMDQ=$vmdq CNA=$cna
							#exit -1
						fi
					fi
				fi
				echo
				echo ----------------------------
			done
		done
	done

	#RSS and CNA

	echo ----------------------------
	echo RSS + CNA
	echo -----------------------------
	echo

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
	txdefret=$(ssh $target ethtool -S $vmnic | grep -i queue | grep -i byte | grep -i tx | wc -l)
	echo Found the default VMDQ tx queue size: $txdefret
	rxdefret=$(ssh $target ethtool -S $vmnic | grep -i queue | grep -i byte | grep -i rx | wc -l)
	echo Found the default VMDQ rx queue size: $rxdefret
	echo

	for rss in 0 1
	do
		for cna in 0 1
		do
			echo Unload the driver
			ssh $target esxcfg-module -u ixgbe
			echo Wait $sleeptime seconds
			sleep $sleeptime

			echo
			echo Load the driver with CNA=$cna RSS=$rss
			ssh $target esxcfg-module ixgbe CNA=$cna,$cna RSS=$rss,$rss
			echo Wait $sleeptime seconds
			sleep $sleeptime

			echo Count the number of queues
			txret=$(ssh $target ethtool -S $vmnic | grep -i queue | grep -i byte | grep -i tx | wc -l)
			echo Found the default VMDQ tx queue size: $txret
			rxret=$(ssh $target ethtool -S $vmnic | grep -i queue | grep -i byte | grep -i rx | wc -l)
			echo Found the default VMDQ rx queue size: $rxret
			echo

			if [ $rss == 0 ]; then
				if [ $cna == 0 ]; then
					if [ $txret == $txdefret ]; then
						echo PASSED: Expected $txdefret queues, and found $txret queues
					else
						echo FAILED: Expected $txdefret queues, but found $txret queues
						#exit -1
					fi
					if [ $rxret == $rxdefret ]; then
						echo PASSED: Expected $rxdefret queues, and found $rxret queues
					else
						echo FAILED: Expected $rxdefret queues, but found $rxret queues
					fi
				else
					if [ $txret == $(expr $txdefret + 1) ]; then
						echo PASSED: Expected $(expr $txdefret + 1) queues, and found $txret queues
					else
						echo FAILED: Expected $(expr $txdefret + 1) queues, but found $txret queues
					fi
					if [ $rxret == $(expr $rxdefret + 1) ]; then
						echo PASSED: Expected $(expr $rxdefret + 1) queues, and found $rxret queues
					else
						echo FAILED: Expected $(expr $rxdefret + 1) queues, but found $rxret queues
					fi
				fi
			else
				if [ $cna == 0 ]; then
					if [ $txret == $(expr $txdefret + 1) ]; then
						echo PASSED: Expected $(expr $txdefret + 1) queues, and found $txret queues
					else
						echo FAILED: Expected $(epxr $txdefret + 1) queues, but found $txret queues
					fi
					if [ $rxret == $(expr $rxdefret + 4) ]; then
						echo PASSED: Expected $(expr $rxdefret + 4) queues, and found $rxret queues
					else
						echo FAILED: Expected $(expr $rxdefret + 4) queues, but found $rxret queues
					fi
				else
					if [ $txret == $(expr $txdefret + 1) ]; then
						echo PASSED: Expected $(expr $txdefret + 1) queues, and found $txret queues
					else
						echo FAILED: Expected $(expr $txdefret + 1) queues, but found $txret queues
					fi
					if [ $rxret == $(expr $rxdefret + 1) ]; then
						echo PASSED: Expected $(expr $rxdefret + 4) queues, and found $rxret queues
					else
						echo FAILED: Expected $(expr $rxdefret + 4) queues, but found $rxret queues
					fi

				fi
			fi
		done
	done
fi
exit
