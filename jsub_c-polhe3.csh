#!/bin/csh -fb
# 
#Create A1N|D2N job submission script for JLab batch farm
#
#usage: jsub_c-polhe.csh <inp_file> <job_start> <num_jobs> [mc_dir=/volatile/hallc/c-polhe3/jixie/mc-single-arm]
################################################################
set DEBUG = " "
#set DEBUG = (echo)

set cur_dir = (`pwd`)
if ( $#argv < 3 ) then
    echo "**************************************************************************************************"
    echo "You need to provide at least 3 arguments"
    echo "usage: jsub_c-polhe3.csh <inp_file> <run_number_start> <number_of_jobs> [mc_dir=/volatile/hallc/c-polhe3/jixie/mc-single-arm]"  
    echo "       job_start is the starting run number for the job, start from 0;"
    echo "       num_jobs is the number of runs you want to create;"
    echo "       you have to specify the number of events in the input file."
    echo "example 1: $0:t dump.inp 0 128 "
    echo "example 2: $0:t dump.inp 0 128 /work/my_mc_dir"
    echo "**************************************************************************************************"
    #not enough arguments, exit -999 ...
    exit -999 
endif

########################################################################

set inp_file = ($1)
if !(-f $inp_file) then
  echo "could not find input file $inp_file, I quit ..."
  exit -1
endif
set inp_path = `dirname $cur_dir/$inp_file`
cd $inp_path; set inp_path = `pwd`; cd $cur_dir 
set inp_file_abs = $inp_path/${inp_file:t}
set job_name = $inp_file:t:r
set run_start = ($2)
set num_jobs = ($3)

set mc_dir = /volatile/hallc/c-polhe3/jixie/mc-single-arm
if ( $# >= 4 ) set mc_dir = ($4)
if !(-d $mc_dir) then
  echo "mc-single-arm dir '$mc_dir' not exist, I quit ..."
  exit -1
endif
#get absolute path
cd $mc_dir; set mc_dir = `pwd`; cd $cur_dir 
mkdir -p ${mc_dir}/outfiles ${mc_dir}/worksim

#check for write permission
mkdir -p ${mc_dir}/outfiles/temp$$
if !(-d ${mc_dir}/outfiles/temp$$) then
  echo "You do not have write permission in $mc_dir, I quit ..."
  exit -1
else
  rm -fr ${mc_dir}/outfiles/temp$$
endif

########################################################################

set count = (0)
while ( $count < ${num_jobs} )
	@ run = ${run_start} + ${count}
	set runxxx = `printf "%03i\n" $run`
	#create job file to run this cmd
	#cmd:/volatile/hallc/c-polhe3/jixie/mc-single-arm/go_batchfarm.csh $inp_file $run_min $run_max

	############################################################
	set jobfiledir = (`pwd`/job_files)
	mkdir -p $jobfiledir;
	#create the $template
	set template = ($jobfiledir/job_${job_name}_$runxxx)
	echo "Creating job file $template"
	echo "PROJECT: c-polhe3" >&! $template
	echo "TRACK:   simulation" >> $template
	echo "OS:   centos77" >> $template
	echo "MEMORY: 2048 MB" >> $template
	echo "TIME: 4000" >> $template
	echo "JOBNAME: ${job_name}_$runxxx" >> $template
	echo "COMMAND: $mc_dir/go_batchfarm.csh $inp_file_abs $run $run ${mc_dir}" >> $template
	############################################################

	#uncomment the following 2 lines if you want to submit this job immediately
	cat $template
	$DEBUG jsub $template

	@ count = $count + 1 
end
