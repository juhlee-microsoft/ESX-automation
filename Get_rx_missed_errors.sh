esxcfg-module -u ixgbe
sleep 2
esxcfg-module ixgbe
sleep 2
for i in 1 2 3 4 5 6 7 8 9 10
do
echo Print rx_missed at count $i
ethtool -S vmnic7 | grep -i rx_missed
echo Waiting 5 min ...
sleep 300
done
