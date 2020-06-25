vmware -v
echo -------------------------------------
esxcli hardware platform get
echo -------------------------------------
esxcfg-nics -l
echo -------------------------------------
ethtool -i vmnic5
echo -------------------------------------
echo VF initial
lspci | grep -i vf
echo -------------------------------------
esxcfg-module -u ixgbe
sleep 10
echo -------------------------------------
esxcfg-module ixgbe
sleep 10
echo -------------------------------------
ethtool -S vmnic5 | grep queue
echo -------------------------------------
echo NO VF expected
lspci | grep -i vf
echo -------------------------------------
vmkload_mod -u ixgbe
sleep 10
echo -------------------------------------
vmkload_mod ixgbe
sleep 10
echo -------------------------------------
ethtool -S vmnic5 | grep queue
echo -------------------------------------
echo NO VF expected
lspci | grep -i vf
echo -------------------------------------
esxcfg-module -u ixgbe
sleep 10
echo -------------------------------------
esxcfg-module ixgbe max_vfs=8,8,8,8 VMDQ=16,16,16,16
sleep 10
echo -------------------------------------
ethtool -S vmnic5 | grep queue
echo -------------------------------------
lspci | grep -i vf
echo -------------------------------------
vmkload_mod -u ixgbe
sleep 10
echo -------------------------------------
vmkload_mod ixgbe max_vfs=8,8,8,8 VMDQ=16,16,16,16
sleep 10
echo -------------------------------------
ethtool -S vmnic5 | grep queue
echo -------------------------------------
lspci | grep -i vf
echo -------------------------------------
