#!/bin/bash
export PATH=$PATH:$ROOTSYS/bin
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$ROOTSYS/lib:.:/usr/lib:/usr/lib/system
EVENTS=0
INIFILE=CLA.ini
VERBOSE=5000
datafile=$1
datatype=$2

if [ $# -lt 2 ]; then
 echo ERROR: not enough arguments
 echo $0  ROOTfile_name  ROOTfile_type [-h]
 cat $0 | grep '|-'|grep -v grep| cut -f1 -d')'
 echo "ROOT file type can be:"; grep "inptype ==" ../CLA/CLA.C | cut -f3 -d'=' | cut -f1 -d')'
 exit 1
fi

POSITIONAL=()
while [[ $# -gt 2 ]]
do
key="$3"

case $key in
    -i|--inifile)
    INIFILE="$4"
    shift # past argument
    shift # past value
    ;;
    -e|--events)
    EVENTS="$4"
    shift # past argument
    shift # past value
    ;;
    -h|--help)
    echo command line arguments:
    cat $0 | grep '|-'|grep -v grep| cut -f1 -d')'
    echo "ROOT file type can be:"; grep "inptype ==" ../CLA/CLA.C | cut -f3 -d'=' | cut -f1 -d')'
    exit 1
    ;;
    -v|--verbose)
    VERBOSE="$4"
    shift # past argument
    shift # past value
    ;;
    --default)
    DEFAULT=YES
    shift # past argument
    ;;
    *)    # unknown option
    POSITIONAL+=("$1") # save it in an array for later
    shift # past argument
    ;;
esac
done
set -- "${POSITIONAL[@]}" # restore positional parameters

#echo INIFILE  = "${INIFILE}"
#echo EVENTS   = "${EVENTS}"
#echo VERBOSE  = "${VERBOSE}"


cat ${INIFILE} | grep -v '#' | grep "region " > pippo
cat ${INIFILE} | grep -v '#' | grep "algo " >> pippo
Nalgo=`cat pippo | wc -l`
rm pippo

if [ $Nalgo -gt 1 ]; then
 echo Analysis with Multiple Regions
 ../scripts/separate_algos.sh ${INIFILE}
else
 echo Simple Analysis
 cp ${INIFILE} BP_1-card.ini
 Nalgo=1
fi
 
 for ialgo in `seq $Nalgo`; do
  ../scripts/ini2txt.sh  BP_$ialgo
 done

if [ `echo $LD_LIBRARY_PATH | grep CLA > /dev/null ; echo $?` -ne 0 ]; then
   export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:../CLA/
fi

rm histoOut-BP_*.root
echo ../CLA/CLA.exe $datafile -inp $datatype -BP $Nalgo -EVT $EVENTS -V ${VERBOSE}
../CLA/CLA.exe $datafile -inp $datatype -BP $Nalgo -EVT $EVENTS -V ${VERBOSE}
if [ $? -eq 0 ]; then
  rbase=`echo ${INIFILE} | rev | cut -d'/' -f 1 | rev|cut -f1 -d'.'`
  rm   histoOut-${rbase}.root 
  hadd histoOut-${rbase}.root histoOut-BP_*.root
fi
