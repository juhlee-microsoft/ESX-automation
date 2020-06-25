#!/bin/sh
export target=$1
export drv=$2
export vmnic1=$3
export waittime=30
echo
echo Validate the driver $2 reload in ESX $1, and exercise $vmnic1
echo
if [ -z $3 ]; then
	echo ERROR --------------------------------------------------------------------------
	echo USAGE: $0 \<IP ADDRESS OF TARGET ESX\> \<DRIVER NAME\> \<VMNIC FOR VERIFICATION\>
	echo ERROR --------------------------------------------------------------------------
	echo
	exit
fi
sleep 1

for i in esxcfg-module vmkload_mod
do
	echo
	echo 1\) Unload the driver $drv in ESX $target \($i\)
	echo
	echo Archive vmkernel log to tmp directory
	ret=$(ssh $target 'cp /var/log/vmkernel.log /tmp/pre.log')
	sleep 1
	ret=$(ssh $target $i -u $2)
	echo Wait $waittime seconds
	sleep $waittime
	echo Archive vmkernel log to tmp directory
	ret=$(ssh $target 'cp /var/log/vmkernel.log /tmp/post.log')
	sleep 1

	ret=$(ssh $target esxcfg-nics -l | grep $vmnic1)
	if [ -z "$ret" ]; then
		echo
		echo PASSED - Driver unloaded successfully
		echo
		echo Analyzing vmkernel log
		echo
		for k in unregistered unload destroyed
		do
			ret=$(ssh $target diff /tmp/pre.log /tmp/post.log | grep -i $k)
			if [ -z "$ret" ]; then
				echo WARNING Found missing contents $k in vmkernel log
				echo Please check out vmkernel log manually
				echo
			else
				echo Found $k in vmkernel diff
			fi
		done
	else
		echo
		echo FAILED - Driver unloading failed.
		echo
		exit
	fi

	echo
	echo 2\) Load the driver $drv in ESX $target \($i\)
	echo
	echo Archive vmkernel log to tmp directory
	ret=$(ssh $target 'cp /var/log/vmkernel.log /tmp/pre.log')
	sleep 1
	ret=$(ssh $target $i $2)
	echo Wait $waittime seconds
	sleep $waittime
	echo Archive vmkernel log to tmp directory
	ret=$(ssh $target 'cp /var/log/vmkernel.log /tmp/post.log')
	sleep 1

	ret=$(ssh $target esxcfg-nics -l | grep $vmnic1)
	if [ -n "$ret" ]; then
		echo
		echo PASSED - Driver loaded successfully
		echo
		echo Analyzing vmkernel log
		echo
		ret=$(ssh $target diff /tmp/pre.log /tmp/post.log | grep -i $k)
		for k in loaded NetQueue MSIX loading
		do
			if [ -z "$ret" ]; then
				echo WARNING Found missing contents $k in vmkernel log
				echo Please check out vmkernel log manually
				echo
			else
				echo Found $k in vmkernel diff
			fi
		done
	else
		echo
		echo FAILED - Driver loading failed.
		echo
		exit
	fi
done

