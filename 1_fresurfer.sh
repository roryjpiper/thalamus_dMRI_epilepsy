#!/bin/bash

# Define group , e.g. GROUP = SEEG or GROUP = resections or GROUP = controls
read -p 'Group: ' g

# Define session name 
read -p 'Session: ' s

export FREESURFER_HOME=/home/[DIRECTORY]/software/freesurfer
SUBJECTS_DIR=/home/[DIRECTORY]/Documents/${g}/output/freesurfer
source $FREESURFER_HOME/SetUpFreeSurfer.sh


for i in sub*; do

t1w_in=/home/rorypiper/Documents/lgs/input/source_data/${i}/${s}/anat/${i}_${s}_T1w.nii.gz
recon-all -subject ${i} -all -i ${t1w_in} -sd ${SUBJECTS_DIR}
	
done
