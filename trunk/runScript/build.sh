#!/bin/bash
if [ $# -ne 1 ]; then
    echo -e "Usage: ./build.sh [syncmode]"
    echo -e "syncmode: sync or async\n"
    exit 1
fi

syncmode=$1
#ZKJAR=/proj/EMS/rsproj/zookeeper/zookeeper-3.4.6.jar
#ZKPATH=/proj/EMS/rsproj/zookeeper-3.3.6
ZKPATH=/proj/EMS/rsproj/zookeeper-3.4.6
LOG4J=/proj/EMS/rsproj/apache-log4j-1.2.17
JAVATEST=/proj/EMS/rsproj/javatest/mytest1
cd $JAVATEST
rm $JAVATEST/*.class

if [ "$syncmode" = "sync" ]
then
    javac -g -cp $LOG4J/log4j-1.2.17.jar:$ZKPATH/zookeeper-3.4.6.jar:$ZKPATH/lib/slf4j-api-1.6.1.jar $JAVATEST/zksimpleTest.java
elif [ "$syncmode" = "async" ]
then
    javac -g -cp $LOG4J/log4j-1.2.17.jar:$ZKPATH/zookeeper-3.4.6.jar:$ZKPATH/lib/slf4j-api-1.6.1.jar $JAVATEST/zksimpleTestAsync.java
else
    echo -e "please enter 'sync' or 'async' correctly\n"
    exit 1
fi
