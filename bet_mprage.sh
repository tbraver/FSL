#!/bin/bash

# Written by Andrew Poppe (poppe076@umn.edu) 05/04/2012
# Additional contributions/generalizations by M.Harms 05/17/2012
# MODIFED FOR USE WITH INDIV-2 BY TSB 03/27/2013

# This script brain-extracts the MPRAGE nifti files
# It is somewhat time consuming (due to use of the -B option in bet).

#Location of AFNI installation
AFNI_loc=/export/local/linux64/2.6/pkg/afni/
#Location of Freesurfer installation
FREE_loc=/export/local/linux64/2.6/pkg/freesurfer/bin/
#Location of Python 2.6+ (but under 3.0)
#SHOULD THIS BE UPDATED TO PYTHON 2.7? -- TSB
py_loc=/export/local/linux64/2.6/pkg/python2.6/bin/
#Location of FSL installation
#NOTE - USED FSL5 LOCATION TO ENABLE USE OF FSL_ANAT
FSL_loc=/export/local/linux64/2.6/pkg/fsl5/bin/
FSLDIR="/export/local/linux64/2.6/pkg/fsl5/bin/"
#Set paths
PATH=${py_loc}:${AFNI_loc}:${FREE_loc}:${FSL_loc}:${PATH}


## NEED TO CHECK ON AB14064 SINCE FIDL FILE ONLY SHOWS 5 RUNS, BUT APPEARS TO BE CORRECT NUMBER OF BOLD EPI FILES
## List of subjects: ab13531 ab13570 ab13593 ab13656 ab13681 ab13724 ab13780 ab13794 ab13795 ab14055 ab14064 ab14123 ab14137 ab14154 ab14181 ab14195 ab14196 ab14197 ab14233 ab14235 ab14249 ab14250 ab14251 ab14281 ab14302 ab14303 ab14355 ab14357 ab14381 ab14469 ab14470 ab14516 ab14537 ab14538 ab14539 ab14599 ab14600 ab14603 ab14632 ab14649 ab14665 ab14702 ab14713 ab14717 ab14719 ab14720 ab14763 ab14780 ab14781 ab14782 ab14828 ab14842 ab14845 ab14846 ab14876 ab14944 ab14961 ab14962 ab14963 ab15003 ab15027 ab15028 ab15029 ab15092 ab15093 ab15095 ab15124 ab15188 ab15197 ab15198 ab15199 ab15251 ab15255 ab15256 ab15311 ab15411 ab15448 ab15504 ab15523 ab15525 ab15526 ab15712 ab15864 ab15885 ab15927 ab15944 ab16047 ab16049 ab16077 ab16078 ab16161 ab16162 ab16207 ab16208
#Removed: ab15774 ab13583 ab13807 ab16184 ab13847 ab15239 ab15777 ab13727 ab14337 ab15520
#Added: ab14828 ab14842 ab14845 ab14846 ab14876 ab14944 ab14961

echo "******** BEGIN $0 $(date) ********"

# TSB - NOT USING SOURCE_FILE APPROACH; MOVING RELEVANT VARIABLES TO THIS SCRIPT
# source source_file.sh
scriptdir=`pwd`

# Ensure that FSL outputs as .nii.gz (scripts assume that)
export FSLOUTPUTTYPE=NIFTI_GZ

# This is the main working directory within which are all the data folders
# Needs to be the full (absolute) path (not a relative path)


wd="/data/nil-external/ccp/INDIV-2/TSB_analyses/2012/FSL_PROCESSING/"


FAILURES_FILE=$wd/failures.txt

cd $wd

# keep a log of failures
echo -e "\n#### $0 $(date) ####" >> $FAILURES_FILE

## Define subjects
#allSubjects=${subjects[@]}     ## defined in source_file.sh
#allSubjects=`ls -1d C4*`

# NEED TO MODIFY THIS TO DO DIFFERENT SUBJECTS
allSubjects="ab13531"

# Option to use -B  option with bet (reduces image bias and residual neck voxels); makes runtime slower
# (1=use -B; 0=don't use -B)
useB=0

# Option to use fsl_anat instead of bet -- supposedly works better (with FNIRT) but slower
# (1=use fsl_anat; 0=use bet)
useFslAnat=0

#dir=$wd/structs
# cd $dir

for subj in $allSubjects; do
    cd $subj
    files=(`ls mprage*.nii.gz | grep -v brain`) # list all the mprage files, excluding already bet'ed files
    if [ ${#files[@]} -eq 0 ] ; then
	echo "$subj: No T1w structural exists. $(date)" >> $FAILURES_FILE
	continue
    fi

    if [ ${useB} -eq 1 ]; then
         bval="-B"
    else
	 bval=""
    fi

    for file in ${files[@]}; do # loop through the mprage files
	echo "------"
        # insert '_brain' into output file name
	brain=`$FSLDIR/bin/remove_ext $file`_brain
	
         if [ ${useFslAnat} -eq 0 ]; then 
        	# run brain extraction tool
		if [ `imtest $brain` -eq 0 ] || [ $redobet -ne 0 ] ; then
	    		$FSLDIR/bin/bet $file $brain -f 0.3 $bval -v
		else
	    		echo "$file: bet already run ($brain exists)"
		fi
         fi
         if [ ${useFslAnat} -eq 1 ]; then 
        	# run fsl_anat tool
		if [ `imtest $brain` -eq 0 ] || [ $redobet -ne 0 ] ; then
	    		$FSLDIR/bin/fsl_anat -i $file --noseg --nosubcortseg --weakbias
		else
	    		echo "$file: bet already run ($brain exists)"
		fi
         fi
	echo
    done
done

echo "******** END $0 $(date) ********"; echo
