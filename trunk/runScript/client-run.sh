#!/bin/bash
if [ $# -ne 9 ]; then
   echo -e "Usage: ./client-run.sh [mode] [dataloc] [#process] [#clients] [rec_time] [total_time] [numz] [heapsize] [syncmode]"
   echo -e "mode: [1] standalone, [2] ensemble"
   echo -e "dataloc: [1] local, [2] shared"
   echo -e "#process: number of background zktest processes"
   echo -e "#clients: number of clients to launch the processes"
   echo -e "rec_time/total_time: record time and total execution time interval"
   echo -e "numz: number of znode"
   echo -e "heapsize: size of heap in MB"
   echo -e "sync mode: sync or async\n"
   exit 1
fi

exemode=$1
dloc=$2
nprocs=$3
nclients=$4
rectm=$5
maxtm=$6
numz=$7
heapsize=$8
syncmode=$9
echo -e "exemode $1, dloc $2, nprocs $3, rectm $rectm, maxtm $5 \n"

JAVATEST=/proj/EMS/rsproj/javatest/mytest1
#ZKPATH=/proj/EMS/rsproj/zookeeper
ZKPATH=/proj/EMS/rsproj/zookeeper-3.4.6
ZKJAR=$ZKPATH/zookeeper-3.4.6.jar
#ZKPATH=/proj/EMS/rsproj/zookeeper-3.3.6
#ZKJAR=$ZKPATH/zookeeper-3.3.6.jar
LOG4J=/proj/EMS/rsproj/apache-log4j-1.2.17


if [ "$syncmode" = "sync" ]
then
    EXE=zksimpleTest
elif [ "$syncmode" = "async" ]
then
    EXE=zksimpleTestAsync
else
    echo -e "please enter 'sync' or 'async' correctly\n"
    exit 1
fi

cd $JAVATEST

## Connect to multiple servers
#hostname=10.1.1.2:2181,10.1.1.3:2181,10.1.1.4:2181
## Connect to oneself
#hostname=127.0.0.1:2181
## Single Node connection
#hostname=10.1.1.2:2181

if [ "$exemode" = "standalone" ]
then
    hostname=node-1:2181
elif [ "$exemode" = "ensemble" ]
then
    hostname=node-1:2181,node-2:2181,node-3:2181
else
    echo -e "please enter 'standalone' or 'ensemble' correctly\n"
    exit 1
fi
echo -e "use $exemode hosts: $hostname"

#rootdir=$1
#numznodes=$((10*1024))
numznodes=  #100

iters=6000
##rectm=$((5*60*1000))
##maxtm=$((10*60*1000))
##sleeptm=$(($maxtm/1000 + 60))
base=512
metasize=512

if [ $dloc = "local" ]
then
    RES=/mnt/zkres
elif [ $dloc = "shared" ]
then
    RES=$JAVATEST/res
else
    echo -e "please enter 'local' or 'shared' correctly\n"
    exit 1
fi

upoutdir=$RES/$exemode-$dloc

#str=$1
#str=${str#*/}

OUTFILE=
znodepath=
runtest() {
  #for inc in 0 #{1..4}
  #metasize=$(($base * $((2**$inc)) ))
  # echo -e "$EXE $hostname $numznodes $metasize $iters $steps\n"
  OUTFILE=$OUTDIR/$1
  heapsizestring=$2
  numberofznodes=$3
  sudo touch $OUTFILE
  sudo chmod 777 $OUTFILE
  znodepath=$(echo /$prefix-$incproc)
  #sleep 15
  echo -e "## test $heapsizestring (heapsz) $numberofznodes znodes ($znodepath), meta size $metasize bytes, iters $iters, steps $steps\n" >> $OUTFILE 
  #java $heapsizestring \
  java -Xms128m -Xmx128m \
  -cp ".:$ZKPATH/conf/*:$LOG4J/log4j-1.2.17.jar:$ZKJAR:$ZKPATH/lib/*" \
  $EXE $hostname $znodepath $numberofznodes $metasize $iters $rectm $maxtm $OUTFILE
  ## | tee -a $RES/zk-$numznodes-$metasize-$str
}

voidrun() {
# echo -e "I received $1\n"
for iter in {1..2}
do
	sleep 1 #200
    echo -e "zook test $i iters\n"
done
}


##############
#### main ####
##############
prefix=$(awk -F. '{print $1}' <<< `hostname`)
##st=400
##inc=100
nc=$nclients   # number of clients

##for procs in $(eval echo {$st..$nprocs..$inc}) 
##do
procs=$nprocs
OUTDIR=
heapstr=
#for incproc in $(seq 1 $procs)
#echo -e "test of $procs clients before wait: $(date) \n"
for incproc in $(eval echo {1..$(($procs/$nc))})
do
  # for heapsize in 64 128 256
  # do
  # for numz in 100 500 1000
  # do
  heapstr="-Xmx${heapsize}m"
  OUTDIR="${upoutdir}/p${procs}-h${heapsize}-nz${numz}"
  sudo mkdir -p $OUTDIR
  runtest $prefix-$incproc $heapstr $numz &
  # done
  # done
  #echo -e "runtest $prefix-$incproc under $OUTDIR"
done

wait
#sleep $sleeptm

# for i in `pgrep java`
# do 
# 	sudo kill -9 $i
# done
echo -e "client-run.sh done with [$procs] test ...\n"

#(echo -e "\n\nrmr /$prefix-$incproc\n\nquit\n\n") | ../../zookeeper-3.4.6/bin/zkCli.sh -server $hostname

if [ $dloc = "local" ] #&& $prefix = "node-2"]
then
    sleep 1
    #ssh node-1 "sudo rm -rf /mnt/zklogs/version-2/log.*"
    #ssh node-1 "sudo rm -rf /mnt/zkdata/version-2/snapshot.*"
else #[ $dloc = "shared" ]
	sudo rm -rf /proj/EMS/rsproj/data/zkdata/version-2/snapshot.*
	sudo rm -rf /proj/EMS/rsproj/data/zklogs/version-2/log.*
fi
