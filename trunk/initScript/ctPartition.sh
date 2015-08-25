#!/bin/bash
if [ $# -ne 2 ]; then
   echo -e "Usage: ./ctPartition.sh [diskdir] [size]"
   echo -e "diskdir: sda, sdb ... sdX"
   echo -e "size: 10M, 30G OR all\n"
   exit 1
fi
diskdir=$1
size=$2
if [ $size = "all" ]
then
	#echo -e "give me all disk!\n"
    (echo p; echo d; echo o; echo n; echo p; echo 1; echo ; echo ; echo p; echo w) | sudo fdisk /dev/$diskdir
else
	#echo -e "give me $size space!\n"
    (echo p; echo d; echo o; echo n; echo p; echo 1; echo ; echo +${size}; echo p; echo w) | sudo fdisk /dev/$diskdir
fi
echo -e "Create one $size partition on /dev/$diskdir\n"
