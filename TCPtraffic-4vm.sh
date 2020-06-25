#!/bin/bash
#####################################################
#### Filename: TCPtraffic-4vm.sh
#### Description: This is 4x VM netperf TCP traffic
####  running.
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

	vm3=192.168.0.202
	test3=192.168.8.202

	vm4=192.168.0.206
	test4=192.168.8.206

	vm5=192.168.0.203
	test5=192.168.8.203

	vm6=192.168.0.207
	test6=192.168.8.207

	vm7=192.168.0.204
	test7=192.168.8.204

	vm8=192.168.0.208
	test8=192.168.8.208

	echo
	echo ESX $dutesx has a vSwitch $vsw, the porgroup $pg, and uplink the $dutvmnic
	echo ESX $auxesx has a vSwitch $vsw, the porgroup $pg, and uplink the $auxvmnic
	echo 4 ESX systems are rebooted, and start TCP traffic for $trafficduration seconds
	echo

	sleep 1

	echo $(date) Create a vSwitch, $vsw, in ESX $dutesx
	ssh $dutesx esxcfg-vswitch -a $vsw
	echo
	echo $(date) Create a vSwitch, $vsw, in ESX $auxesx
	ssh $auxesx esxcfg-vswitch -a $vsw
	echo

	sleep 1

	echo $(date) Add a portgroup, $pg, in ESX $dutesx
	ssh $dutesx esxcfg-vswitch -A $pg $vsw
	echo
	echo $(date) Add a portgroup, $pg, in ESX $auxesx
	ssh $auxesx esxcfg-vswitch -A $pg $vsw
	echo

	sleep 1

	echo $(date) Uplink vmnic, $dutvmnic, to the vSwitch, $vsw, in ESX $dutesx
	ssh $dutesx esxcfg-vswitch -L $dutvmnic $vsw
	echo

	echo $(date) Uplink vmnic, $auxvmnic, to the vSwitch, $vsw, in ESX $auxesx
	ssh $auxesx esxcfg-vswitch -L $auxvmnic $vsw
	echo

	sleep 1

	ssh $dutesx esxcfg-vswitch -l
	echo
	ssh $auxesx esxcfg-vswitch -l
	echo

	sleep 1

	echo $(date) Systeme rebooting to apply the change
	ssh $dutesx reboot
	echo $(date) Rebooted the system $dutesx
	echo
	ssh $auxesx reboot
	echo $(date) Rebooted the system $auxesx
	echo

	for x in 1 2 3 4 5 6 7 8 9 10 11
	do
		echo Waiting 60 seconds \($x/11\)
		sleep 60
	done

	for i in $vm1 $vm2 $vm3 $vm4 $vm5 $vm6 $vm7 $vm8
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

	echo $(date) Run netperf traffic from $vm1 to $vm2
	ssh $vm1 netperf -H $test2 -l $trafficduration -t TCP_STREAM &

	sleep 1

	echo $(date) Run netperf traffic from $vm2 to $vm1
	ssh $vm2 netperf -H $test1 -l $trafficduration -t TCP_STREAM &

	sleep 1

	echo $(date) Run netperf traffic from $vm3 to $vm4
	ssh $vm3 netperf -H $test4 -l $trafficduration -t TCP_STREAM &

	sleep 1

	echo $(date) Run netperf traffic from $vm4 to $vm3
	ssh $vm4 netperf -H $test3 -l $trafficduration -t TCP_STREAM &

	sleep 1

	echo $(date) Run netperf traffic from $vm5 to $vm6
	ssh $vm5 netperf -H $test6 -l $trafficduration -t TCP_STREAM &

	sleep 1

	echo $(date) Run netperf traffic from $vm6 to $vm5
	ssh $vm6 netperf -H $test5 -l $trafficduration -t TCP_STREAM &

	sleep 1

	echo $(date) Run netperf traffic from $vm7 to $vm8
	ssh $vm7 netperf -H $test8 -l $trafficduration -t TCP_STREAM &

	sleep 1

	echo $(date) Run netperf traffic from $vm8 to $vm7
	ssh $vm8 netperf -H $test7 -l $trafficduration -t TCP_STREAM &

	echo

	echo $(date) Wait for netperf traffic completion 70 seconds
	sleep 70

	echo $(date) Complete the traffic test, and destroy the vSwitch setup

	echo $(date) Power down VMs
	echo

	for i in $vm1 $vm2 $vm3 $vm4 $vm5 $vm6 $vm7 $vm8
	do
		ssh $i 'shutdown -f -h 0'
	done

	echo $(date) Waiting 60 seconds for VM shutdown \(1/1\)
	echo

	sleep 60

	echo $(date) Delete the vSwitch, $vsw. in ESX $dutest
 	ssh $dutesx esxcfg-vswitch -d $vsw
	echo
	echo $(date) Delete the vSwitch, $vsw. in ESX $auxest
 	ssh $auxesx esxcfg-vswitch -d $vsw
	echo

	sleep 1

	echo $(date) List vSwitch in ESX $dutesx
	ssh $dutesx esxcfg-vswitch -l
	echo
	echo $(date) List vSwitch in ESX $auxesx
	ssh $auxesx esxcfg-vswitch -l
	echo
fi

