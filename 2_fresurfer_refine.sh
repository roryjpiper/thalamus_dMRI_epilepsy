#!/bin/bash

export FREESURFER_HOME=/home/[DIRECTORY]/software/freesurfer
SUBJECTS_DIR=${PWD}
source $FREESURFER_HOME/SetUpFreeSurfer.sh

for i in sub*; do

recon-all -autorecon2-cp -autorecon3 -s $i -sd ${PWD}

done
