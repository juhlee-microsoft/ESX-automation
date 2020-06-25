#!/usr/bin/sh
#####################################################
#### Filename: ChangeMTU.sh
#####################################################
i=0
waittime=30
errwaittime=10
drivername=igb
vswitch=vSwitch1

while true
do
	i=$(($i+1))
	echo --------------------------------
	echo ------ Iteration $i
	echo ------ The current Date and Time
	date
	echo --------------------------------
	rem=$(($i % 2))
	if [ $rem -eq 0 ]
	then
		mtu=9000
	else
		mtu=1500
	fi
	echo Going to MTU $mtu
	esxcfg-vswitch -m $mtu $vswitch
	sleep 1
	esxcfg-vswitch -l $vswitch
	echo Waiting $waittime seconds
	sleep $waittime
	check=$(esxcfg-nics -l | grep $drivername | grep Down)
	if [ -n "$check" ]
	then
		echo "WARN: found link down event"
		echo "WARN: first location to find link down" >> /var/log/vmkernel.log
		echo dump out register
		ethtool -d vmnic2 > /tmp/vmnic2-register-dump1.out
		echo "Check out the link status 3 more times"
		linkup=f
		for x in 1 2 3
		do
			echo wait $x times of $errwaittime seconds delay
			sleep $errwaittime
			check=$(esxcfg-nics -l | grep $drivername | grep Down)
			if [ -n "$check" ]
			then
				echo link still down.....
			else
				echo link up finally
				linkup=t
			fi
		done
		if [ "$linkup" != t ]
		then
			echo "ERROR: Found Link still down"
			echo "ERROR $drivername LINK DOWN " >> /var/log/vmkernel.log
			esxcfg-nics -l | grep $drivername
			cp /var/log/vmkernel.log /tmp/vmkernel.log
			echo dump out register
			ethtool -d vmnic2 > /tmp/vmnic2-register-dump2.out
			exit
		else
			echo False alarm.....
			echo continue testing
		fi
	else
		echo "Not found. Testing continue"
	fi
done
