#!/bin/bash
if [ $# -ne 2 ]; then
  echo -e "Usage: ./operf-stat.sh [mode] [clients]"
  echo -e "mode: sys or pid"
  echo -e "clients: number of client processes\n"
  exit 1
fi

OPERFDIR=/users/vdr007/install/oprofile/bin
VMIMAGE=/proj/EMS/rpms/source-build/linux-source-3.13.0/vmlinux
mode=$1
procs=$2
exemode=$(./bin/zkServer.sh status | grep Mode | awk '{print $NF}')
echo -e "\n sleep and record time are based on client side setting ... \n"
sleeptm=$((5*60))
rectm=$((10*60))
resdir=opreport-res/$exemode-$procs-$mode-$rectm
sudo mkdir -p $resdir

date
sleep $sleeptm
date

if [ "$mode" = "sys" ]
then
  sudo $OPERFDIR/operf --callgraph --system-wide --vmlinux=/proj/EMS/rpms/source-build/linux-source-3.13.0/vmlinux &
elif [ "$mode" = "pid" ]
then
  sudo $OPERFDIR/operf --callgraph -p `pgrep java` --vmlinux=/proj/EMS/rpms/source-build/linux-source-3.13.0/vmlinux &
else
  echo -e "please enter 'sys' or 'pid' correctly\n"
  exit 1
fi

echo -e "\n"
sleep 2
echo -e "\n"
sleep 2
echo -e "\n"
sleep $rectm
echo -e "\n"
date

for i in `pgrep operf`
do
    sudo kill -SIGINT $i
    echo -e "kill operf pid $i \n"
done

echo -e "\n"
sleep 2

# if [ "$mode" = "pid" ]
# then
#   sudo $OPERFDIR/opreport -l `which java` --image-path=/lib/modules/3.13.0-33-generic/kernel -g -f -a -o $resfile
# else
#   sudo $OPERFDIR/opreport -l --image-path=/lib/modules/3.13.0-33-generic/kernel -g -f -a -o $resfile
# fi

# sudo $OPERFDIR/opreport --image-path=/lib/modules/3.13.0-33-generic/kernel -l -o $resdir/all-basic
# echo -e "\n\n"
# sudo $OPERFDIR/opreport --image-path=/lib/modules/3.13.0-33-generic/kernel -l -f -o $resdir/all-basic-full
# echo -e "\n\n"
# sudo $OPERFDIR/opreport --image-path=/lib/modules/3.13.0-33-generic/kernel -l -g -a -o $resdir/all-complex
# echo -e "\n\n"
# sudo $OPERFDIR/opreport --image-path=/lib/modules/3.13.0-33-generic/kernel -c -g -% -o $resdir/all-globalcount
# echo -e "\n\n"
# 
# sudo $OPERFDIR/opreport `which java` --image-path=/lib/modules/3.13.0-33-generic/kernel -l -o $resdir/java-basic
# echo -e "\n\n"
# sudo $OPERFDIR/opreport `which java` --image-path=/lib/modules/3.13.0-33-generic/kernel -l -f -o $resdir/java-basic-full
# echo -e "\n\n"
# sudo $OPERFDIR/opreport `which java` --image-path=/lib/modules/3.13.0-33-generic/kernel -l -g -a -o $resdir/java-complex
# echo -e "\n\n"
# sudo $OPERFDIR/opreport `which java` --image-path=/lib/modules/3.13.0-33-generic/kernel -c -g -% -o $resdir/java-globalcount
# 
# echo -e "done \n"
