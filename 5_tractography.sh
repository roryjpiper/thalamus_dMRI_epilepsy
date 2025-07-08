#!/bin/sh

# Add software prerequisites
export FREESURFER_HOME=/home/[directory]/software/freesurfer
source $FREESURFER_HOME/SetUpFreeSurfer.sh
export ANTSPATH=/home/[directory]/software/install/bin/
export PATH=${ANTSPATH}:$PATH

export NIFTYREG_INSTALL=/home/[directory]/software/nifty_git/niftyreg/install
PATH=${PATH}:${NIFTYREG_INSTALL}/bin
LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:${NIFTYREG_INSTALL}/lib
export PATH
export LD_LIBRARY_PATH

# Define group , e.g. GROUP = SEEG or GROUP = resections or GROUP = controls
read -p 'Group: ' GROUP

# Define session name 
read -p 'Session: ' session_name

# LOOP THROUGH SUBJECTS

for i in sub*; do

echo $i

# SET THE BASES
atlas_base=[directory]/thomas_dMRI/$GROUP/output/freesurfer/${i}/mri
diffusion_base=[directory]/thomas_dMRI/$GROUP/output/dwi/${i}/${session_name}/mrtrix

# RUN THE GENERIC DIFFUSION PROCESSING (i.e. not specific to scale)

# Convert the freesurfer brain to original subject native space
mri_vol2vol --mov ${atlas_base}/brain.mgz --targ ${atlas_base}/orig/001.mgz --regheader --o ${atlas_base}/brain_native.mgz --nearest
mrconvert $atlas_base/brain_native.mgz $atlas_base/brain_native.nii.gz -force
rm ${atlas_base}/brain_native.mgz

# generate a transform (T1w --> diffusion space)
reg_aladin -flo $atlas_base/brain_native.nii.gz -ref $diffusion_base/${i}_${session_name}_nodif.nii.gz -aff $diffusion_base/${i}_${session_name}_t12diff.txt -res $diffusion_base/${i}_${session_name}_diff_space_brain.nii.gz -rigOnly


# 5 tissue map
5ttgen fsl [directory]/Documents/$GROUP/input/source_data/$i/${session_name}/anat/${i}_${session_name}_T1w.nii.gz $diffusion_base/${i}_${session_name}_5tt_native.nii.gz -force

# Move 5tt to diffusion space
reg_resample -flo $diffusion_base/${i}_${session_name}_5tt_native.nii.gz -ref $diffusion_base/${i}_${session_name}_nodif.nii.gz -aff $diffusion_base/${i}_${session_name}_t12diff.txt -res $diffusion_base/${i}_${session_name}_5tt.nii.gz -inter 0

# Make tracts
tckgen $diffusion_base/${i}_${session_name}_wm.mif -act $diffusion_base/${i}_${session_name}_5tt.nii.gz -select 5000000 -seed_dynamic $diffusion_base/${i}_${session_name}_wm.mif $diffusion_base/${i}_${session_name}_5M.tck -force

tcksift2 $diffusion_base/${i}_${session_name}_5M.tck $diffusion_base/${i}_${session_name}_wm.mif $diffusion_base/${i}_${session_name}_5M_sift.txt -force


done


