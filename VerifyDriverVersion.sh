#!/bin/bash
#########################
#### Date Sept 5 2012
#########################
# get driver name and target
echo What is the ESX IP ADDRESS?
read x
export target=$x
echo What is the driver name?
read x
export driver=$x
ssh $target esxcfg-nics -l | grep $driver
