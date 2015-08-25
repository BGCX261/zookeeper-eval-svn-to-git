#!/bin/bash
if [ $# -ne 5 ]; then
   echo -e "Usage: ./run-benchmark.sh [begin] [end] [incr] [mode] [#clients]"
   echo -e "begin/incr/end: number of processes to run"
   echo -e "mode: standalone, ensemble"
   echo -e "#clients: number of clients to launch the processes \n"
   exit 1
fi

begin=$1
end=$2
inc=$3
mode=$4
clients=$5

upoutdir=/mnt/zkres/$mode-local
logoutput=
recordtime=$((15*60*1000))
maxtime=$((20*60*1000))
sleeptm=$(($maxtime/1000 + 1*60))

host=$(echo `hostname` | awk -F. '{print $1}')

for procs in $(eval echo {$begin..$end..$inc})
do
  for heapsz in 64 128 256
  do
  for numz in 100 500 1000
  do
  date
  timeout --preserve-status $sleeptm bash ./client-run.sh $mode local $procs $clients $recordtime $maxtime $numz $heapsz &> /dev/null ##$logoutput
  date

  echo -e "done with [$procs] test ...\n"

  if [ "$mode" = "standalone" ] && [ "$host" = "node-4" ]
  then
    ssh node-1 "sudo rm -rf /mnt/zklogs/version-2/log.*"
    ssh node-1 "sudo rm -rf /mnt/zkdata/version-2/snapshot.*"
    ssh node-1 "/proj/EMS/rsproj/zookeeper-3.4.6/initServer.sh $mode local $procs 0"
  fi

  if [ "$mode" = "ensemble" ] && [ "$host" = "node-4" ]
  then
	for hi in node-1 node-2 node-3
	do
      ssh $hi "sudo rm -rf /mnt/zklogs/version-2/log.*"
      ssh $hi "sudo rm -rf /mnt/zkdata/version-2/snapshot.*"
      sleep 2
      ssh node-1 "/proj/EMS/rsproj/zookeeper-3.4.6/initServer.sh $mode local $procs 0"
	  echo -e "$host done restart with $hi \n"
    done
  fi

  if [ "$mode" = "ensemble" ] && [ "$host" = "node-5" ]
  then
    ssh node-2 "/proj/EMS/rsproj/zookeeper-3.4.6/initServer.sh $mode local $procs"
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
    ssh node-3 "/proj/EMS/rsproj/zookeeper-3.4.6/initServer.sh $mode local $procs"
	echo -e "$host done restart with node-3\n"
  fi

  done
  done
done

sudo cp -r $upoutdir /proj/EMS/rsproj/javatest/mytest1/result/
