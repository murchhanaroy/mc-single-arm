#!/bin/tcsh
#############################################################
# script to run mc-single-arm in batch farm
# By Jixie Zhang, March 8, 2021
# mc-single-arm need to read input file from ../infiles/, and place 
# output files #into ../outfiles/ and ../worksim/
# It allows to run only one single job with the same input file at a time
# My solution is to rename the input file ....
#############################################################

#load your cern and root installation here
source /apps/root/5.34.36/setroot_CUE.csh

#the job will be executed at this location, 
#you need to change it to your version since you could not write my dir
set WORKSPACE = /volatile/hallc/c-polhe3/jixie/mc-single-arm 

if($#argv < 1) then
  echo "Error, you need to provide at lease one argument"
  echo "Usage: $0:t <path_to_inputfile> [run_min=1] [run_max=1] [WORKSPACE=/volatile/hallc/c-polhe3/jixie/mc-single-arm]"
  echo "       the given inputfile must be stored inside $WORKSPACE/infiles/"
  exit
endif

set inp0 = ($1:t:r)
set runmin = 1
if($#argv >= 2) set runmin = ($2)
set runmax = 1
if($#argv >= 3) set runmax = ($3)
if($runmax < $runmin) set runmax = ($runmin)

#set WORKSPACE = /volatile/hallc/c-polhe3/jixie/mc-single-arm   #already defined above
if ( $# >= 4 ) set mc_dir = ($4)
if !(-d $WORKSPACE) then
  echo "mc-single-arm dir '$WORKSPACE' not exist, I quit ..."
  exit -1
endif

set curdir = `pwd`

cd $WORKSPACE/src

if !(-f ../infiles/${inp0}.inp) then
    echo "input file $1 does not exist, I quit..." 
    exit
endif


set run = ($runmin)
while ($run <= $runmax) 

  set key = (${run})
  if ($run < 10) then
    set key = (00${run})
  else if ($run < 100) then
    set key = (0${run})
  endif
 
  #to allow multiple jobs at the same time, rename the inputfile
  set inp = ${inp0}_${key}
  cp -f ../infiles/${inp0}.inp ../infiles/${inp}.inp

  echo "Start mc-single-arm for run# ${run}, please wait with patient ... "
  rm -f ../worksim/${inp}.rzdat ../outfiles/${inp}.out  
  ./mc_single_arm << endofinput #> ../outfiles/${inp}_${run}.log
${inp}
endofinput

  echo "convert paw ntuple to root tree ... "
  h2root ../worksim/${inp}.rzdat ../worksim/${inp}.root
  ls -lh ../worksim/${inp}.root  #to show the file size
    
  #remove the temp inp file and rzdat file
  if (-f ../worksim/${inp}.root) then
    rm -f ../infiles/${inp}.inp
    rm -f ../worksim/${inp}.rzdat
  endif

  @ run = $run + 1
end
cd $curdir
