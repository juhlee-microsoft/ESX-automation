target=$1
vmnic=$2

for i in 0 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 
do 
#ssh $target vsish -e get /net/pNics/$vmnic/rxqueues/queues/$i/info | grep active
ssh $target vsish -e get /net/pNics/$vmnic/rxqueues/queues/$i/info 

done

