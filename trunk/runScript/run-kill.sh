#!/bin/bash
if [ $# -ne 6 ]; then
   echo -e "Usage: ./run-kill.sh [begin] [end] [incr] [mode] [#clients] [syncmode]"
   echo -e "begin/incr/end: number of processes to run"
   echo -e "mode: standalone, ensemble"
   echo -e "#clients: number of clients to launch the processes"
   echo -e "syncmode: sync or async\n"
   exit 1
fi

begin=$1
end=$2
inc=$3
mode=$4
clients=$5
syncmode=$6

#ZKPATH=/proj/EMS/rsproj/zookeeper
ZKPATH=/proj/EMS/rsproj/zookeeper-3.4.6
#ZKPATH=/proj/EMS/rsproj/zookeeper-3.3.6
upoutdir=/mnt/zkres/$mode-local
logoutput=
recordtime=$((10*60*1000))
maxtime=$((20*60*1000))
sleeptm=$(($maxtime/1000 + 2*60))
##iochktm=$((maxtime/(1000*60)))
# ./client-run.sh standalone local 400 &> /dev/null
# echo -e "launched test and wait for $sleeptm seconds\n"

serverlog=/proj/EMS/rsproj/zookeeper-3.4.6/zklogs

host=$(echo `hostname` | awk -F. '{print $1}')

for procs in $(eval echo {$begin..$end..$inc})
do
  for heapsz in 128 #64 128 256
  do
  for numz in 100 #500 1000
  do
  logoutput=/mnt/zkres/logs-$procs-$host
  sudo touch $logoutput
  sudo chmod 775 $logoutput
  #ssh node-1 "$ZKPATH/chk-iotop.sh $procs $iochktm"
  date
  timeout --preserve-status $sleeptm bash ./client-run.sh $mode local $procs $clients $recordtime $maxtime $numz $heapsz $syncmode &> $logoutput #/dev/null
  ##./client-run.sh $mode local $procs $clients $recordtime $maxtime &> $logoutput
  date
  #echo -e "date;timeout --preserve-status $sleeptm ./client-run.sh standalone local $procs $recordtime $maxtime &> /dev/null;date\n"
  ##sleep $sleeptm

  # for i in `pgrep java`
  # do 
  # 	sudo kill -9 $i
  # 	echo -e "sudo kill -9 $i \n"
  # done
  echo -e "done with [$procs] test ...\n"

  if [ "$mode" = "standalone" ] && [ "$host" = "node-2" ]
  then
    ssh node-1 "sudo rm -rf /mnt/zklogs/version-2/log.*"
    ssh node-1 "sudo rm -rf /mnt/zkdata/version-2/snapshot.*"
    ssh node-1 "$ZKPATH/initServer.sh $mode local $procs 0"

	# ssh node-1 "for javapid in `pgrep java`; do sudo kill -9 $javapid; done"
	# sleep 10
	# ssh node-1 "sudo cp $shprofdir/zk.hprof.txt $shprofdir/$mode-$procs-$clients; sudo rm $shprofdir/zk.hprof.txt"
    # sleep 10
  fi

  if [ "$mode" = "ensemble" ] && [ "$host" = "node-4" ]
  then
    sudo grep "timer LAST" $serverlog/zookeeper.log > $serverlog/$syncmode-$mode-$procs-log
    #sudo rm $serverlog/zookeeper.log
	for hi in node-1 node-2 node-3
	do
      ssh $hi "sudo rm -rf /mnt/zklogs/version-2/log.*"
      ssh $hi "sudo rm -rf /mnt/zkdata/version-2/snapshot.*"
      sleep 2
      ssh node-1 "$ZKPATH/initServer.sh $mode local $procs 0"
	  echo -e "$host done restart with $hi \n"
    done
  fi

  if [ "$mode" = "ensemble" ] && [ "$host" = "node-5" ]
  then
    ssh node-2 "$ZKPATH/initServer.sh $mode local $procs"
    ssh node-2 "sudo rm -rf /mnt/zklogs/version-2/log.*"
    sleep 30
    ssh node-2 "sudo rm -rf /mnt/zkdata/version-2/snapshot.*"
	echo -e "$host done restart with node-2\n"
  fi

  if [ "$mode" = "ensemble" ] && [ "$host" = "node-6" ]
  then
    ssh node-3 "sudo rm -rf /mnt/zklogs/version-2/log.*"
    ssh node-3 "sudo rm -rf /mnt/zkdata/version-2/snapshot.*"
    sleep 30
    ssh node-3 "$ZKPATH/initServer.sh $mode local $procs"
	echo -e "$host done restart with node-3\n"
  fi

  done
  done
done

sudo cp -r $upoutdir /proj/EMS/rsproj/javatest/mytest1/result/
