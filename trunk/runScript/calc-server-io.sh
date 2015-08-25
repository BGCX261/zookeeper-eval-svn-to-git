#!/bin/bash
#upper=$1

### subroutine ###
tmpavg=
tmpallavg=
calcavg() {
list=$(echo "$1/*")

for file in $list
do
	sudo chmod 775 $file
    if [ -s $file ]
    then
       grep -v "^#" $file | awk '{print $1, $2}' >> $file.tmp 
    else
       echo -e "find empty file $file\n"
    fi
  
    awk '{ if ($1 > 1000 && $2 > 1000) print $1, $2 }' $file.tmp > $file-filter.tmp
    tmpavg=$(awk '{sum1+=$1; sum2+=$2} END {printf("%.0f \t %.0f\n", sum1/NR, sum2/NR)}' $file-filter.tmp)
    tmpallavg=$(awk '{sum1+=$1; sum2+=$2} END {printf("%.0f \t %.0f\n", sum1/NR, sum2/NR)}' $file.tmp)
    sudo echo -e "=============\n avg   : $tmpavg \n" >> $file
    sudo echo -e "=============\n avgall: $tmpallavg \n" >> $file
	rm -rf $1/*.tmp
done

}

newlist=$(echo "$1/*.tmp")

### main routine ###
upper=.
firstdir=$(echo "$upper/server-iotop-logs")

for item in $firstdir
do
	itemstr=$(awk -F/ '{print $2}' <<< $item)
	#echo -e "## $itemstr"

	for it in $firstdir
	do
		calcavg $it
	done
done
