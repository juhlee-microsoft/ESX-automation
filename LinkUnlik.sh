#!/bin/sh
#####################################################
#### Filename: LinkUnlink.sh
#### Description: This needs some prework before exe-
####  cute the script. 2x ESX have each vSwitch. DUT
####  and AUX needs vSwitch1 each, and a single vmnic
####  added.
####  The number of VMs start traffic, and run this
####  script to verify the Link change over traffic.
#####################################################
if [ -z $3 ]
then
	echo $(date) ERROR -----------------------------------------------------------
	echo $(date) USAGE: $0 \<IP ADDRESS OF TARGET ESX\> \<VSWITCH_NAME\> \<VMNIC\>
	echo $(date) ERROR -----------------------------------------------------------
else
	i=0
	waittime=30
	errwaittime=10
	target=$1
	vswitch=$2
	testvmnic1=$3

	while true
	do
		i=$(($i+1))
		echo $(date) ------ Iteration $i

		echo $(date) Do unlink $testvmnic1 in $vswitch
		ssh $target esxcfg-vswitch -U $testvmnic1 $vswitch
		sleep 1

		ssh $target esxcfg-vswitch -l $vswitch
		echo $(date) Waiting $waittime seconds
		sleep $waittime

		echo $(date) Do link $testvmnic1 in $vswitch
		ssh $target esxcfg-vswitch -L $testvmnic1 $vswitch
		sleep 1

		ssh $target esxcfg-vswitch -l $vswitch
		echo $(date) Waiting $waittime seconds
		sleep $waittime

		echo $(date) Verify the link state after uplink op
		check=$(ssh $target esxcfg-nics -l | grep $testvmnic1 | grep -i down)
		if [ -n "$check" ]
		then
			echo $(date) WARN: found link down event
			echo $(date) "WARN: first location to find link down" >> /var/log/vmkernel.log
			echo $(date) Dump out register
			ssh $target ethtool -d $testvmnic1 > /tmp/register-dump1.out
			echo $(date) Check out the link status 3 more times
			linkup=f

			for x in 1 2 3
			do
				echo $(date) Wait $x times of $errwaittime seconds delay
				sleep $errwaittime
				check=$(ssh $target esxcfg-nics -l | grep $testvmnic1 | grep -i down)
				if [ -n "$check" ]
				then
					echo $(date) Link still down.....
				else
					echo $(date) Link up finally
					linkup=t
				fi
			done

			if [ "$linkup" != t ]
			then
				echo $(date) ERROR: Found Link still down
				echo $(date) "ERROR $drivername LINK DOWN " >> /var/log/vmkernel.log
				ssh $target esxcfg-nics -l | grep $drivername
				ssh $target cp /var/log/vmkernel.log /tmp/vmkernel.log
				echo $(date) Dump out register
				ssh $target ethtool -d $testvmnic1 > /tmp/register-dump2.out
				exit
			else
				echo $(date) False alarm.....
				echo $(date) Continue testing
			fi
		else
			echo $(date) "Not found Link-Down state. Testing continue"
		fi
	done
fi
