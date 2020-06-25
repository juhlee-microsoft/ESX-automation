#!/bin/sh
##############################
# User enters the data
##############################
echo
echo 1\) What is the IP address of DUT ESX? The default is 192.168.0.10
echo
read tmp
if [ -z $tmp ]; then
	export dut_esx=192.168.0.10
else
	export dut_esx=$tmp
fi
echo DUT ESX has IP address: $dut_esx
echo It is $(ssh $dut_esx vmware -v)
echo

echo
echo 2\) What is the IP address of AUX ESX? The default is 192.168.0.11
echo
read tmp
if [ -z $tmp ]; then
	export aux_esx=192.168.0.11
else
	export aux_esx=$tmp
fi
echo AUX ESX has IP address: $aux_esx
echo It is $(ssh $aux_esx vmware -v)
echo

echo
echo 3\) This is the list of VM reserved IP address
echo
export dut_vm1=192.168.0.50
export dut_vm2=192.168.0.51
export aux_vm1=192.168.0.60
export aux_vm2=192.168.0.61
echo DUT VM1 has IP address: $dut_vm1
echo DUT VM2 has IP address: $dut_vm2
echo AUX VM1 has IP address: $aux_vm1
echo AUX VM2 has IP address: $aux_vm2
echo

echo
echo 4\) What is the driver name? \[Mandatory\]
echo
read tmp
export driver=$tmp
echo Target driver name is $driver
echo

echo
echo Display vmnic in ESX
echo
ssh $dut_esx esxcfg-nics -l | grep $driver
echo 5\) Can you type the DUT vmnic1 that you want to test? \[Mandatory\]
read tmp
export dut_vmnic1=$tmp
echo 6\) Can you type the DUT vmnic2 that you want to test? \[Mandatory\]
read tmp
export dut_vmnic2=$tmp

ssh $aux_esx esxcfg-nics -l | grep $driver
echo 7\) Can you type the AUX vmnic1 that you want to test? \[Mandatory\]
read tmp
export aux_vmnic1=$tmp
echo 8\) Can you type the AUX vmnic2 that you want to test? \[Mandatory\]
read tmp
export aux_vmnic2=$tmp

echo DUT target HW1 is $dut_vmnic1
echo DUT target HW2 is $dut_vmnic2
echo AUX target HW1 is $aux_vmnic1
echo AUX target HW1 is $aux_vmnic2

tmp=$(ssh $dut_esx ethtool -i $dut_vmnic1 | grep -i version | awk '{print $2}')
echo
echo 9\) What driver version do you test and verify? Found $tmp in $dut_esx, for example.
echo
read tmp
export version=$tmp
echo
echo Taget driver version is $version of $driver
echo

export pingcount=2

echo
echo 10\)Checking ESX connection
echo
ping -c $pingcount $dut_esx
ping -c $pingcount $aux_esx

echo
echo 11\) Checking VM connection
echo
ping -c $pingcount $dut_vm1
ping -c $pingcount $dut_vm2
ping -c $pingcount $aux_vm1
ping -c $pingcount $aux_vm2

echo
echo VP1\) Verify the driver status in ESX
echo
for i in $dut_esx $aux_esx
do
	tmp=$(ssh $i esxcfg-module -l | grep $driver)
	if [ -z "$tmp" ]; then
		echo FAILED - Could not find the driver $driver module in ESX $i
		echo Please check out the driver loading status 
		echo
		exit
	else
		set tmp2=$(echo $tmp | cut -c1-5)
		echo PASSED - the driver $tmp2 is loaded in ESX $i successfully
		echo
	fi

done

echo
echo VP2\) Verify the driver version in $dut_vmnic1 and $dut_vmnic2
echo
for j in $dut_vmnic1 $dut_vmnic2
do
	tmp=$(ssh $dut_esx esxcfg-nics -l | grep $j)
	if [ -z "$tmp" ]; then
		echo FAILED - Please check out the driver loading status in ESX $dut_esx or HW installation. Could not find $j
		echo
		exit
	else
		echo PASSED - Found NIC $tmp
		echo
		ret=$(ssh $dut_esx ethtool -i $j | grep -i driver | awk '{print $2}')
		if [ $ret = $driver ]; then
			echo PASSED - Found driver $driver in the $j
			echo

			ret=$(ssh $dut_esx ethtool -i $j | grep -i -m 1 version | awk '{print $2}')
			tmp=$(expr match $ret $version)
			if [ $tmp -ne 0 ]; then
				echo PASSED - Found the $version in the $j
				echo
			else
				echo FAILED - The driver version does not match. Expected $version, but found $ret
				echo
			fi
		else
			echo FAILED - Could not found the driver $driver in the $j
			echo
		fi
	fi
done

echo
echo VP3\) Verify the driver version in $aux_vmnic1 and $aux_vmnic2
echo
for j in $aux_vmnic1 $aux_vmnic2
do
	tmp=$(ssh $aux_esx esxcfg-nics -l | grep $j)
	if [ -z "$tmp" ]; then
		echo FAILED - Please check out the driver loading status in ESX $aux_esx or HW installation. Could not find $j
		echo
		exit
	else
		echo PASSED - Found NIC $tmp
		ret=$(ssh $aux_esx ethtool -i $j | grep -i driver | awk '{print $2}')
		if [ $ret = $driver ]; then
			echo PASSED - Found driver $driver in the $j
			echo

			ret=$(ssh $aux_esx ethtool -i $j | grep -i -m 1 version | awk '{print $2}')
			tmp=$(expr match $ret $version)
			if [ $tmp -ne 0 ]; then
				echo PASSED - Found the $version in the $j
				echo
			else
				echo FAILED - The driver version does not match. Expected $version, but found $ret echo
			fi
		else
			echo FAILED - Could not found the driver $driver in the $j
			echo
		fi
	fi
done
