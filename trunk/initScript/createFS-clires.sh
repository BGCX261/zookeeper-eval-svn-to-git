#!/bin/bash
if [ $# -ne 4 ]; then
   echo -e "Usage: ./createFS.sh [mode] [dataloc] [myid] [diskdir]"
   echo -e "mode: [1] standalone, [2] ensemble (read myid)"
   echo -e "dataloc: [1] local, [2] shared"
   echo -e "myid: 1, 2, ..., numserver"
   echo -e "diskdir: sda1, sdb2, ..., sdX1\n"
   exit 1
fi

mode=$1
dataloc=$2
nodenum=$3
disk=$4
SHDIR=/proj/EMS/rsproj/data

if [ $mode != "standalone" ] && [ $mode != "ensemble" ]
then
    echo -e "please enter 'standalone' or 'ensemble' correctly\n"
    exit 1
fi

if [ $dataloc != "local" ] && [ $dataloc != "shared" ]
then
    echo -e "please enter 'local' or 'shared' correctly\n"
    exit 1
fi


if [ "$dataloc" = "local" ]
then
    ## Step 1: create and mount file system ##
	sudo umount /mnt/zkres
	sudo rm -rf /mnt/zkres
    echo -e "\numount previous local file system ...\n"
	sleep 2
    echo y | sudo mkfs -t ext4 /dev/$disk
    echo -e "\ncreate local file system ...\n"
	sleep 2
    sudo file -s /dev/$disk
    sudo mkdir -p /mnt/zkres
    sudo mount /dev/$disk /mnt/zkres
    echo -e "\nmount local file system ...\n"
    df /dev/$disk

    ## Step 2: create files and directories ##
    echo -e "\ncreate zookeeper directory and files ...\n"
    sudo chmod 777 /mnt
    sudo chmod -R 777 /mnt/zkres

	sudo mount
    
else
	#echo -e "data in $dataloc, clean previous stuff and skip fs mount ...\n"
    rm -rf $SHDIR/zkdata/*
    rm -rf $SHDIR/zklogs/*
    echo -e "clean shared data and log files\n"
	##mkdir -p $SHDIR/zkdata $SHDIR/zklogs
fi
