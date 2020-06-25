target1=$1
target2=$2
IT=$3
ssh $target1 esxcfg-module -u ixgbe
ssh $target2 esxcfg-module -u ixgbe
sleep 3
ssh $target1 esxcfg-module ixgbe InterruptThrottleRate=$IT
ssh $target2 esxcfg-module ixgbe InterruptThrottleRate=$IT
sleep 5
ssh $target1 cat /var/log/vmkernel.log | grep $IT
ssh $target2 cat /var/log/vmkernel.log | grep $IT
sleep 60
ssh $target1 esxtop -b -a -n 60 > /tmp/nnt-3.14.0.8-$IT.csv
sleep 1

