#!/bin/bash
if [ -z $2 ]; then
	echo ERROR -----------------------------------------------------
	echo USAGE: $0 \<IP ADDRESS OF TARGT ESX\> \<VIB FILE\>
	echo ERROR -----------------------------------------------------
else
	vib=$2
	target=$1
	echo
	echo Driver installation started
	echo
	echo Target system is $target
	echo
	echo VIB file name is $vib
	echo
	echo ---------------------------
	echo OS Information
	ssh $target esxcli system version get
	echo
	echo ---------------------------
	ssh $target esxcli hardware platform get
	echo
	echo ---------------------------
	echo CPU Type
	ssh $target esxcli hardware cpu list | grep -i core
	echo
	echo ---------------------------
	echo Memory info
	ssh $target esxcli hardware memory get
	echo ---------------------------
	echo
	if [ $(echo $vib | cut -c20-22) == "ixg" ]; then
		echo This is about ixgbe driver update or installation
		echo
		if [[ "$vib" =~ "ixgbe" ]]; then
			ssh $target esxcli network nic list | grep ixgbe
			vmnics=$(ssh $target esxcli network nic list | grep ixgbe | cut -c1-7)
			for i in $vmnics
			do
				echo ---------------------------
				echo Display $i info
				ssh $target ethtool -i $i
				echo
			done
		else
			echo Abort the installation. Can not find appropriate driver in vib file.
			exit
		fi
	elif [ $(echo $vib | cut -c5-7) == "igb" ]; then
		echo This is about igb driver update or installation
		echo
		if [[ "$vib" =~ "igb" ]]; then
			ssh $target esxcli network nic list | grep igb
			vmnics=$(ssh $target esxcli network nic list | grep igb | cut -c1-7)
			for i in $vmnics
			do
				echo ---------------------------
				echo Display $i info
				ssh $target ethtool -i $i
				echo
			done
		else
			echo Abort the installation. Can not find appropriate driver in vib file.
			exit
		fi
	else
	 	echo Unknown driver or could not detect driver name in vib file
		echo This may be from the Eng driver file name change. The installation will
		echo be in progress shortly.
		echo
		#exit
	fi
	echo
	echo Copy a vib file to the target system
	echo
	scp /opt/intel/esx/$vib root@$target:/tmp
	echo Execute the VIB installation
	echo
	fnonly="${vib##*/}"
	ret=$(ssh $target esxcli software vib install -v /tmp/$fnonly --no-sig-check)
	if [[ "$ret" =~ "successfully" ]]; then
		echo Installation successful
		echo Reboot the system to complete the installation
		echo
		ssh $target reboot
		for i in 60 120 150 180 240 300
		do
			echo Waiting...
			sleep 60
			echo $i out of 300 seconds
			echo
		done

		echo Verifying the pNic in the system
		ret=$(ssh $target esxcli network nic list | grep -i ixgbe | grep -i vmnic | cut -c1-8)
		ssh $target ethtool -i $(echo $ret | cut -c1-7)
	else
		echo Installation failed. Please check out the currently installed version.
		echo
		echo See below error
		echo $ret
	fi
fi
exit
