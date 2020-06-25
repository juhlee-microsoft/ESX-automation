#!/bin/bash
echo USAGE: $0 my_path my_target
echo Remounting in 5 seconds

sleep 5

mypath=$1
freq=1
target=$2

orgin=$(find $mypath -mtime $freq -type f | grep -i vib)

if [ -n "$orgin" ]; then
	echo Found change - $orgin
	echo Copy vib file to the local folder
	scp $orgin .
	sleep 1
	./InstallVIB.sh $target $orgin
fi
