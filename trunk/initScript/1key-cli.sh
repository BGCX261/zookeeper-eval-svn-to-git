#!/bin/bash
if [ $# -ne 2 ]; then
	echo -e "Usage: 1key-cli.sh [mode] [cli_id]"
    echo -e "mode: standalone, ensemble (read myid)"
	echo -e "cli_id: the id for the client, e.g. 1, 2, 3 \n"
   exit 1
fi

mode=$1
cliid=$2

HOMEDIR=/users/vdr007
ZKDIR=/proj/EMS/rsproj/zookeeper-3.4.6

$HOMEDIR/ctPartition.sh sdb 200G
$HOMEDIR/createFS-clires.sh $mode local $cliid sdb1
echo -e "\n client-$cliid done with the setting \n"

clipath=/proj/EMS/rsproj/javatest/mytest1
cd $clipath
