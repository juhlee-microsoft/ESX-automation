#!/bin/bash
target=$1
vmnic=$2
ssh $target ethtool -S $vmnic | grep -i rx_queue | grep -i byte
