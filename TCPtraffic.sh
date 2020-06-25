#!/bin/bash
#####################################################
#### Filename: TCPtrafficU.sh
#### Description: This is simple netperf TCP traffic
####  running between a single vm to vm.
#####################################################
if [ -z $4 ]
then
	echo ERROR -------------------------------------------------------
	echo USAGE: $0 \<DUT ESX\> \<AUX ESX\> \<DUT VMNIC\> \<AUX VMNIC\>
	echo ERROR -------------------------------------------------------
else
	dutesx=$1
	auxesx=$2
	vsw=vSwitch1
	pg=testpg
	dutvmnic=$3
	auxvmnic=$4
	trafficduration=60
	vm1=192.168.0.201
	test1=192.168.8.201
	vm2=192.168.0.205
	test2=192.168.8.205

	echo $(date) ESX $dutesx has a vSwitch $vsw, the porgroup $pg, and uplink the $dutvmnic
	echo $(date) ESX $auxesx has a vSwitch $vsw, the porgroup $pg, and uplink the $auxvmnic
	echo $(date) 2 ESX systems are rebooted, and start TCP traffic for $trafficduration seconds

	for i in $dutesx $auxesx
	do
		echo $(date) Create a vSwitch, $vsw, in ESX $i
		ssh $i esxcfg-vswitch -a $vsw

		sleep 1

		echo $(date) Add a portgroup, $pg, in ESX $i
		ssh $i esxcfg-vswitch -A $pg $vsw

		sleep 1
	done

	echo $(date) Uplink vmnic, $dutvmnic, to the vSwitch, $vsw, in ESX $dutesx
	ssh $dutesx esxcfg-vswitch -L $dutvmnic $vsw

	echo $(date) Uplink vmnic, $auxvmnic, to the vSwitch, $vsw, in ESX $auxesx
	ssh $auxesx esxcfg-vswitch -L $auxvmnic $vsw

	sleep 1

	ssh $dutesx esxcfg-vswitch -l
	ssh $auxesx esxcfg-vswitch -l

	sleep 1

	echo $(date) Systeme rebooting to apply the change
	ssh $dutesx reboot
	ssh $auxesx reboot

	for x in 1 2 3 4 5 6 7 8 9 10 11
	do
		echo $(date) Waiting 60 seconds \($x/11\)
		sleep 60
	done

	for i in $vm1 $vm2
	do
		echo $(date) Cleaning up the previous netserver process
		ssh $i 'killall netserver'
		sleep 1
		echo $(date) Running netserver
		ssh $i netserver
		ssh $i 'ps aux | grep netserver'
		echo $(date) Verified the netserver running
		echo
		echo $(date) Verifying if VM, $i, reach to AUX ESX, $auxesx
		ssh $i ping -c 3 -q $auxesx | grep loss
		echo
		echo $(date) Verifying if VM, $i, reach to DUT ESX, $dutesx
		ssh $i ping -c 3 -q $dutesx | grep loss
		echo
	done

	echo $(date) Run netperf traffic to VM2, $vm2, in VM1, $vm1
	ssh $vm1 netperf -H $test2 -l $trafficduration -t TCP_STREAM &

	sleep 1

	echo $(date) Run netperf traffic to VM1, $vm1, in VM2, $vm2
	ssh $vm2 netperf -H $test1 -l $trafficduration -t TCP_STREAM &

	echo $(date) Wait 70 seconds to complete the traffic.

	sleep 70

	echo $(date) Complete the traffic test, and destroy the vSwitch setup

	echo $(date) Power down VMs
	ssh $vm1 shutdown -f -h 0
	ssh $vm2 shutdown -f -h 0

	echo $(date) waiting 60 seconds \(1/1\)

	sleep 60

	echo $(date) Delete the vSwitch, $vsw, in ESX $dutest
	ssh $dutesx esxcfg-vswitch -d $vsw

	echo $(date) Delete the vSwitch, $vsw, in ESX $auxest
	ssh $auxesx esxcfg-vswitch -d $vsw

	sleep 1

	echo $(date) List vSwitch in ESX $dutesx
	ssh $dutesx esxcfg-vswitch -l

	echo $(date) List vSwitch in ESX $auxesx
	ssh $auxesx esxcfg-vswitch -l
fi
