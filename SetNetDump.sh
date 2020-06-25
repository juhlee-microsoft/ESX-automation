if [ -z $2 ]
then
	echo ---------------------------
	echo Usage $0 ESX VCVA
	echo ---------------------------
	exit
else
	target=$1
	vcva=$2
fi

echo Setting Netdump in the ESX $target
echo By using VCVA server $vcva

echo Disabling local dump
ssh $target 'esxcfg-dumppart -d'

echo Creaing netdump vmknic
check=$(ssh $target esxcfg-vmknic -l | grep netdump)
if [ -n "$check" ]
then
	echo Found netdump vmk1. No need to create this time.
else
	ssh $target 'esxcfg-vswitch -A netdump vSwitch0'
	ssh $target 'esxcfg-vmknic -a netdump -i DHCP'
	ssh $target 'esxcfg-vmknic -l'
fi

echo Restarting netdump service in VCVA
ssh $vcva service vmware-netdumper restart

echo Setting netdump network in ESX $target
ssh $target esxcli system coredump network set -v vmk1 -i $vcva -o 6500
ssh $target esxcli system coredump network set -e 1
ssh $target esxcli system coredump network get
