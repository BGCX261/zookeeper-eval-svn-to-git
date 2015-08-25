#!/bin/bash
if [ $# -ne 5 ]; then
   echo -e "Usage: ./createFS.sh [mode] [dataloc] [myid] [datadisk] [logdisk]"
   echo -e "mode: [1] standalone, [2] ensemble (read myid)"
   echo -e "dataloc: [1] local, [2] shared"
   echo -e "myid: 1, 2, ..., numserver"
   echo -e "[data|log]disk: sda1, sdb2, ..., sdX1\n"
   exit 1
fi

mode=$1
dataloc=$2
nodenum=$3
datadisk=$4
logdisk=$5
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
	sudo rm -rf /mnt/zkdata/*
	sudo rm -rf /mnt/zklogs/*
	sudo umount /mnt/zkdata
	sudo umount /mnt/zklogs
    echo -e "\numount previous local file system ...\n"
	sleep 2
    echo y | sudo mkfs -t ext4 /dev/$datadisk
	sleep 2
    echo y | sudo mkfs -t ext4 /dev/$logdisk
    echo -e "\ncreate local file system ...\n"
	sleep 2
    sudo file -s /dev/$datadisk
    sudo file -s /dev/$logdisk
    sudo mkdir -p /mnt/zkdata
    sudo mkdir -p /mnt/zklogs
    sudo mount /dev/$datadisk /mnt/zkdata
    sudo mount /dev/$logdisk /mnt/zklogs
    echo -e "\nmount local file system ...\n"
    df /dev/$datadisk
	echo -e "\n"
    df /dev/$logdisk

    ## Step 2: create files and directories ##
    echo -e "\ncreate zookeeper directory and files ...\n"
    #sudo mkdir -p /mnt/zkdata/data
    #sudo mkdir -p /mnt/zkdata/res
    sudo chmod 777 /mnt/zkdata
    sudo chmod 777 /mnt/zklogs
    #if [ ! -d "/mnt/extra/zkexperiment" ]; then
    #mkdir /mnt/extra/zkexperiment
    #fi
    #mkdir -p /mnt/extra/zkexperiment/data /mnt/extra/zkexperiment/logs
    #mkdir -p /mnt/zktest/data /mnt/zktest/logs
    #sudo chmod 777 -R /mnt/zktest
    
    ## create this only with ensemble mode
    if [ "$mode" = "ensemble" ]
    then
        touch /mnt/zkdata/myid
        echo $nodenum > /mnt/zkdata/myid
        echo -e "`hostname`, $nodenum \n"
	else
	    echo -e "$mode mode, skip myid creation ...\n"
	fi
	ls /mnt/zkdata
	ls /mnt/zklogs
    mount  ## check mount status
else
	#echo -e "data in $dataloc, clean previous stuff and skip fs mount ...\n"
    rm -rf $SHDIR/zkdata/*
    rm -rf $SHDIR/zklogs/*
    echo -e "clean shared data and log files\n"
	##mkdir -p $SHDIR/zkdata $SHDIR/zklogs
fi
