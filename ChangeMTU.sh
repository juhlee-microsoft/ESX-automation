#!/bin/sh
#####################################################
#### Description: This needs some prework before exe-
####  cute the script. 2x ESX have each vSwitch. DUT
####  vSwitch1 has 2x vmnic, a teaming mode. AUX vSw-
####  itch has a vmnic.
####  The number of VMs start traffic, and run this
####  script to verify the MTU change over traffic.
#####################################################
if [ -z $5 ]
then
	echo $(date) ERROR ---------------------------------------------------------------------------------------
	echo $(date) USAGE: $0 \<IP ADDRESS OF TARGET ESX\> \<DRIVER NAME\> \<VSWITCH_NAME\> \<VMNIC1\> \<VMNIC2\>
	echo $(date) ERROR ---------------------------------------------------------------------------------------
else
	i=0
	waittime=60
	errwaittime=10
	target=$1
	drivername=$2
	vswitch=$3
	testvmnic1=$4
	testvmnic2=$5

	while true
	do
		i=$(($i+1))
		echo $(date) ------ Iteration $i
		rem=$(($i % 2))
		if [ $rem -eq 0 ]
		then
			mtu=9000
		else
			mtu=1500
		fi

		echo $(date) Changing MTU to $mtu
		ssh $target esxcfg-vswitch -m $mtu $vswitch
		sleep 1
		ssh $target esxcfg-vswitch -l $vswitch
		echo $(date) Waiting $waittime seconds
		sleep $waittime

		check=$(ssh $target esxcfg-nics -l | grep $drivername | grep -i down)
		if [ -n "$check" ]
		then
			echo $(date) WARM: found link down event after $waittime waiting.
			ssh $target echo "first location to find link down" >> /var/log/vmkernel.log
			echo $(date) Check out the link status 3 more times
			linkup=f

			for x in 1 2 3
			do
				echo $(date) Wait $x times of $errwaittime seconds delay
				sleep $errwaittime
				check=$(ssh $target esxcfg-nics -l | grep $drivername | grep -i down)
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
				echo $(date) ERROR: Found Link down after another 3 times checking.
				ssh $target echo "$drivername LINK DOWN " >> /var/log/vmkernel.log
				ssh $target esxcfg-nics -l | grep $drivername
				myret=$(ssh $target esxcfg-nics -l | grep -i down | grep $testvmnic1)
				if [ -n "$myret" ]
				then
					#ssh $target 'ethtool -d $testvmnic1 > /tmp/register-dump-$testvmnic1.out'
					ssh $targt ethtool -s $testvmnic1 wol d
				else
					#ssh $target 'ethtool -d $testvmnic2 > /tmp/register-dump-$testvmnic2.out'
					ssh $targt ethtool -s $testvmnic2 wol d
				fi
				#ssh $target ls -al /tmp/register*
				#echo $(date) Dumped out register
				ssh $target 'cp /scratch/log/vmkernel* /tmp'
				sleep 1
				ssh $target 'md5sum /tmp/vmkernel.log'
				ssh $target 'ls -al /tmp/vmkernel.log'
				exit
			else
				echo $(date) False alarm.....
				echo $(date) Continue testing
			fi
		else
			echo $(date) "Not found. Testing continue"
		fi
	done
fi
