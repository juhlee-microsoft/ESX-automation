partner=$1
bf=$2
testtime=$3

for i in 100 101 102 103 104 105 106 107 116 117 118 119 120 121 122 123
do
ssh $partner netperf -H 192.168.8.$i -l $testtime -f m -P 0 -- -m $bf &
done

for j in 1 2 3 4 5 6 7 8 9 10
do
echo $j out of 10
sleep 60
done
