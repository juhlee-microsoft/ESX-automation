#!/bin/bash
if [ -z $2 ]; then
	echo ERROR -----------------------------------------------------
	echo USAGE: $0 \<IP ADDRESS OF TARGT ESX\> \<VIB FILE\>
	echo ERROR -----------------------------------------------------
else
	vib=$2
	target=$1
	echo ---------------------------
	ssh $target esxcli system version get
	echo
	echo ---------------------------
	ssh $target esxcli hardware platform get
	echo
	echo ---------------------------
	echo CPU Type
	ssh $target esxcli hardware cpu list | grep -i core
	echo
	echo ---------------------------
	echo Memory info
	ssh $target esxcli hardware memory get
	echo ---------------------------
	echo

exit
