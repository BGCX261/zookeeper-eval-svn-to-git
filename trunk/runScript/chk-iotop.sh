#/bin/bash
if [ $# -ne 5 ]; then
	echo -e "./chk-iotop.sh [iotime] [begin] [end] [inc] [server_id]"
	echo -e "[iotime]: io log time in minutes"
	echo -e "[begin, end, inc]: number of processes"
	echo -e "[server_id]: the name of server in ZK config \n"
	exit 1
fi

localdir=/mnt/zkdata
shddir=/proj/EMS/rsproj/javatest/mytest1/result/server-iotop-logs
serverid=$5

for procs in $(eval echo {$2..$3..$4})
do
  file=$localdir/iotop-log-$procs-$serverid
  sudo touch $file
  sudo chmod 777 $file 
  echo -e "### DISK WRITE Statistics with $procs processes on server $serverid " >> $file
  echo -e "### Total   Actual " >> $file
  
  for i in $(eval echo {1..$1})
  do
    sudo iotop -btoPakqq -n 3 -d 20 -u vdr007 | grep "DISK WRITE" | awk '{print $(NF-1)}' | paste -d " "  - - >> $file
    ##sleep $tm
  done
  
  echo -e "### finish log with $1 minutes" >> $file
  sleep 210
done

sudo cp -r $localdir/iotop-log-* $shddir
