#!/bin/bash
target=$1
vmnic=$2
ssh $target vmware -v
ssh $target esxcli system version get
ssh $target esxcli hardware platform get
ssh $target esxcfg-nics -l
ssh $target esxcfg-vswitch -l
ssh $target esxcfg-vmknic -l
ssh $target ethtool -i $vmnic
