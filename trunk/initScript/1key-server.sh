#!/bin/bash
if [ $# -ne 2 ]; then
	echo -e "Usage: 1key-server.sh [mode] [server_id]"
    echo -e "mode: standalone, ensemble (read myid)"
	echo -e "server_id: the myid name for the server, e.g. 1, 2, 3 \n"
   exit 1
fi

mode=$1
serverid=$2
procs=1

HOMEDIR=/users/vdr007
ZKDIR=/proj/EMS/rsproj/zookeeper-3.4.6
#ZKDIR=/proj/EMS/rsproj/zookeeper-3.3.6

$HOMEDIR/ctPartition.sh sdb all
$HOMEDIR/ctPartition.sh sdc all
$HOMEDIR/creatSepeFS.sh $mode local $serverid sdb1 sdc1

# $HOMEDIR/createFS.sh $mode local $serverid sdb1

sleep 3
$ZKDIR/initServer.sh $mode local $procs 0
sleep 3
echo -e "\n recheck the status \n"
$ZKDIR/bin/zkServer.sh status

cd $ZKDIR
