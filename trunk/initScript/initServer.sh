#!/bin/bash
## usage initServer.sh [server_1] [server_n]
if [ $# -ne 4 ]; then
    echo -e "Usage: ./initServer.sh [mode] [dataloc] [procs] [sleeptm]"
    echo -e "mode: [1] standalone, [2] ensemble"
    echo -e "dataloc: [1] local (read myid), [2] shared"
	echo -e "procs: number of client processes"
	echo -e "sleeptm: sleep time in minutes\n"
    exit 1
fi

ZKPATH=/proj/EMS/rsproj/zookeeper-3.4.6
SCRIPTPATH=/proj/EMS/rsproj/javatest
shprofdir=/proj/EMS/rsproj/zookeeper-3.4.6/zk_hprof_dir
lochprofdir=$shprofdir
#lochprofdir=/mnt/zklogs

mode=$1
dataloc=$2
procs=$3
sleeptm=$4
## read dataloc
host=$(echo `hostname` | awk -F. '{print $1}')

if [ $dataloc != "local" ] && [ $dataloc != "shared" ]
then
    echo -e "please enter 'local' or 'shared' correctly\n"
	exit 1
fi

if [ $mode != "standalone" ] && [ $mode != "ensemble" ]
then
    echo -e "please enter 'standalone' or 'ensemble' correctly\n"
	exit 1
fi

cd $ZKPATH

hprofrec() {
stm=$1
sleep $(($stm * 60))
#for javapid in `pgrep java`; do kill -9 $javapid; done

sudo pkill java
sleep 5
#sudo touch $shprofdir/$mode-$procs
sudo echo -e "----- end ----- \n" >> $lochprofdir/zk.hprof.txt
sudo cp $lochprofdir/zk.hprof.txt $shprofdir/zkhprof-new-$mode-$procs-$host
#sudo rm $shprofdir/zk.hprof.txt
echo -e "finish cp and rm old hprof files ...\n"
}

##hprofrec $sleeptm
## stop previous servers ##
$ZKPATH/bin/zkServer.sh stop
sleep 2

if [ "$dataloc" = "local" ]
then
  if [ "$mode" = "standalone" ]
  then
	  echo -e "init local standalone\n"
      cp $ZKPATH/conf/standalone-loc.cfg $ZKPATH/conf/zoo.cfg
  else
	  echo -e "init local ensemble\n"
      cp $ZKPATH/conf/ensemble-loc.cfg $ZKPATH/conf/zoo.cfg
  fi
else
    if [ "$mode" = "standalone" ]
    then
        echo -e "init shared standalone\n"
        cp $ZKPATH/conf/standalone-shd.cfg $ZKPATH/conf/zoo.cfg
    else
        echo -e "init shared ensemble\n"
        cp $ZKPATH/conf/ensemble-shd.cfg $ZKPATH/conf/zoo.cfg
    fi
fi

cat $ZKPATH/conf/zoo.cfg

## start new server and check status ##
#sleep 2
#$ZKPATH/bin/zkServer.sh start
#sleep 3
#$ZKPATH/bin/zkServer.sh status
#
#hprofrec $sleeptm

$ZKPATH/bin/zkServer.sh stop
sleep 3
$ZKPATH/bin/zkServer.sh start
sleep 3
$ZKPATH/bin/zkServer.sh status

# for myid in $(eval echo {$1..$2})
# do
#   # ssh vdr007@node-$myid.mytest.EMS.emulab.net
#   #ssh vdr007@node-$myid bash -c "'
#   ssh vdr007@node-$myid 'bash -s' < $SCRIPTPATH/createDatadir.sh $myid
#   # ssh vdr007@node-$myid 'bash -s' < $ZKPATH/bin/zkServer.sh start
# done

# sleep 5
# 
# for myid in $(eval echo {$1..$2})
# do
#   ssh vdr007@node-$myid 'bash -s' < $ZKPATH/bin/zkServer.sh status
# done
