#!/bin/bash
target=$1
driver=$2
v1=$3
v2=$4
magic1=$5
magic2=$6

echo \-\> Verify the vmnic statistics before
echo
ssh $target ethtool -S $v1
echo
ssh $target ethtool -S $v2
echo \-\> Verify the driver setting
ssh $target esxcfg-module -q | grep -i $driver
ssh $target esxcfg-module -g $driver
echo
echo \-\> Set options on driver
ssh $target esxcfg-module -s \"VMDQ=$magic1,$magic2\" $driver
ssh $target esxcfg-module -e $driver
echo
echo \-\> Verify the driver setting change
ssh $target esxcfg-module -q | grep -i $driver
ssh $target esxcfg-module -g $driver
echo
echo \-\> Verify the vmnic statistics after
echo
ssh $target ethtool -S $v1
echo
ssh $target ethtool -S $v2
echo
echo \-\> Reload the driver with default setting
echo
ssh $target esxcfg-module -u ixgbe
echo Wait 5 seconds until next loading
ssh $target esxcfg-module ixgbe
echo
echo \-\> Verify the problematic vmnic statistics
echo
ssh $target ethtool -S $v1
echo
ssh $target ethtool -S $v2
