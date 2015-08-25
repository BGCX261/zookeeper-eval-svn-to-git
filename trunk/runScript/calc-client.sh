#!/bin/bash

tmpavg=
tmpmax=
tmpmin=
calcavg() {
#echo "hello: $1"
list=$(echo "$1/*")
#echo $list

# check empty file
# find ./standalone-shared/cli-80 -empty

for file in $list
do
  if [ -s $file ]
  then
     grep -v "^#" $file | awk '{print $NF}' >> $file-tmp 
 else
     echo -e "find empty file $file\n"
  fi
done

newlist=$(echo "$1/*-tmp")
#newlist2=$(echo "$1/node-2*.tmp")
#newlist3=$(echo "$1/node-3*.tmp")
#lenlist=${#newlist[@]}
#echo -e "newlist has length of $lenlist \n"
#echo $(newlist[@]:1:$((lenlist/2)))
paste $newlist > $1/sum.tmp

awk '{for(i=t=0;i<NF;) t+=$++i; $0=t}1' $1/sum.tmp > $1/sumc.tmp
tmpavg=$(awk '{sum+=$1} END {printf("%.1f\n", sum/NR)}' $1/sumc.tmp)
tmpmax=$(awk 'BEGIN {max=0} {if($1>max) max=$1} END {printf("%.1f\n", max)}' $1/sumc.tmp)
tmpmin=$(awk 'BEGIN {min=30000} {if($1<min) min=$1} END {printf("%.1f\n", min)}' $1/sumc.tmp)
sudo rm -f $1/*-tmp
#sudo rm -f $1/*tmp
}

upper=$1
#firstdir=$(echo "$upper/*")
#firstdir=$(echo "$upper/ensemble-local")
firstdir=$(echo "$upper/standalone-local")
#echo $firstdir
for item in $firstdir
do
# tmp file to store accumutive vals, e.g. ensemble-tmp
itemstr=$(awk -F/ '{print $2}' <<< $item)
echo -e "avg \t min \t max" > $itemstr.res
echo -e "## it" > $itemstr.clist
seconddir=$(echo "$item/*")
#echo $seconddir
 
for it in $seconddir 
do
itstr=$(awk -F/ '{print $3}' <<< $it)
echo $itstr >> $itemstr.clist
calcavg $it 
echo -e "$tmpavg \t $tmpmin \t $tmpmax" >> $itemstr.res
done
paste $itemstr.clist $itemstr.res | sort -n >> $itemstr.dat
##grep -v "^#" $itemstr.dat | awk '{printf("%d\t %.1f\n", $1, $2/$1, $3/$1, $4/$1)}' >> $itemstr-s.dat
sudo rm $itemstr.clist $itemstr.res
done

#for i in {5..70..5};do echo -e "cli-$i" >> clist; done
#cp zk-result.dat stdsbl.dat localnfs.dat
##paste mylista standalone.res ensemble.res >> stdsbl.dat
##paste mylista standalone.res shared-standalone.res >> localnfs.dat
##grep "^#" stdsbl.dat >> stdsbl-single.dat
##grep -v "^#" stdsbl.dat | awk '{printf("%d\t %.1f\t %.1f\n", $1, $2/$1, $3/$1)}' >> stdsbl-single.dat

# reslist=$(echo "*.res")
# for resfile in $reslist
# do
#   grep -v "^#" $resfile | awk '{print $NF}' >> zk-result.dat
# done
