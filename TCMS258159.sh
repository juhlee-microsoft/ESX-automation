remotehost=$1
netperf -H $remotehost -t TCP_STREAM -l 60 -- -m 1024 s 8192 -S 8192
netperf -H $motehost -t TCP_STREAM -l 60 -- -m 1024 s 32728 -S 32728
netperf -H $remotehost -t TCP_STREAM -l 60 -- -m 4096 s 8192 -S 8192
netperf -H $remotehost -t TCP_STREAM -l 60 -- -m 4096 s 32728 -S 32728
netperf -H $remotehost -t TCP_STREAM -l 60 -- -m 4096 s 57344 -S 57344
netperf -H $remotehost -t TCP_STREAM -l 60 -- -m 8192 s 8192 -S 8192
netperf -H $remotehost -t TCP_STREAM -l 60 -- -m 8192 s 32728 -S 32728
netperf -H $remotehost -t TCP_STREAM -l 60 -- -m 8192 s 57344 -S 57344
netperf -H $remotehost -t TCP_STREAM -l 60 -- -m 32768 s 8192 -S 8192
netperf -H $remotehost -t TCP_STREAM -l 60 -- -m 32768 s 32728 -S 32728
netperf -H $remotehost -t TCP_STREAM -l 60 -- -m 32768 s 57344 -S 57344
netperf -H $remotehost -t TCP_RR -l 60 -- -r 1,1
netperf -H $remotehost -t TCP_RR -l 60 -- -r 64,64
netperf -H $remotehost -t TCP_RR -l 60 -- -r 100,200
netperf -H $remotehost -t TCP_RR -l 60 -- -r 128,8192
netperf -H $remotehost -t UDP_STREAM -l 60 -- -m 64 -s 32768 S 32768
netperf -H $remotehost -t UDP_STREAM -l 60 -- -m 1024 -s 32768 S 32768
netperf -H $remotehost -t UDP_STREAM -l 60 -- -m 1472 -s 32768 S 32768
netperf -H $remotehost -t UDP_STREAM -l 60 -- -m 1500 -s 32768 S 32768
netperf -H $remotehost -t UDP_STREAM -l 60 -- -m 2048 -s 32768 S 32768
netperf -H $remotehost -t UDP_RR -l 60 -- -r 1,1
netperf -H $remotehost -t UDP_RR -l 60 -- -r 64,64
netperf -H $remotehost -t UDP_RR -l 60 -- -r 100,200
netperf -H $remotehost -t UDP_RR -l 60 -- -r 1024,1024
