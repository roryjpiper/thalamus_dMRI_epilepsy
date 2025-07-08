#!/bin/sh

# Add software prerequisites

# mri_convert script needs Freesurfer version 6.0. The two lines below point specifically to this version.
export FREESURFER_HOME=[directory]/software/freesurfer_6.0/
source $FREESURFER_HOME/SetUpFreeSurfer.sh

export ANTSPATH=[directory]/software/install/bin/
export PATH=${ANTSPATH}:$PATH

export NIFTYREG_INSTALL=[directory]/software/nifty_git/niftyreg/install
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
diffusion_base=[directory]/thomas_dMRI/$GROUP/output/dwi/${i}/${session_name}/mrtrix
thomas_atlas=[directory]/thomas_dMRI/$GROUP/output/thomas/${i}/${session_name}
parc_base=[directory]/thomas_dMRI/$GROUP/output/freesurfer/${i}/mri

# LOOP THROUGH SCALES

for scale in $(seq 3) ; do
	
	echo Scale-$scale

	# Copy the T1 file and 'aseg' freesurfer output - aseg needed for intracranial volume correction
	mri_vol2vol --mov ${parc_base}/aseg.mgz --targ ${parc_base}/orig/001.mgz --regheader --o ${thomas_atlas}/aseg.mgz --nearest
	mrconvert ${thomas_atlas}/aseg.mgz ${thomas_atlas}/aseg.nii.gz -force
	rm ${thomas_atlas}/aseg.mgz
	
	# Copy the original Lausanne parcellations to the THOMAS folder
	
	if [ $scale -eq 1 ]; then myaparc=36; fi
	if [ $scale -eq 2 ]; then myaparc=60; fi
	if [ $scale -eq 3 ]; then myaparc=125; fi
	
	mri_vol2vol --mov ${parc_base}/myaparc_${myaparc}.mgz --targ ${parc_base}/orig/001.mgz --regheader --o ${thomas_atlas}/myaparc_${myaparc}.mgz --nearest
	mrconvert ${thomas_atlas}/myaparc_${myaparc}.mgz ${thomas_atlas}/${i}_${session_name}_scale-${scale}_parcellation.nii.gz -force
	rm ${thomas_atlas}/myaparc_${myaparc}.mgz
	
	# Save the whole thalamus for volume purposes (only need scale 1)
	if [ $scale -eq 1 ]; then 	
	rt_thal=49; lt_thal=10;
	fslmaths ${thomas_atlas}/${i}_${session_name}_scale-${scale}_parcellation.nii.gz -thr ${rt_thal} -uthr ${rt_thal} -bin ${thomas_atlas}/${i}_${session_name}_thalamus_right.nii.gz
	fslmaths ${thomas_atlas}/${i}_${session_name}_scale-${scale}_parcellation.nii.gz -thr ${lt_thal} -uthr ${lt_thal} -bin ${thomas_atlas}/${i}_${session_name}_thalamus_left.nii.gz
	fi
		
	# Relabel the myaparc / Lasuanne atlas
	labelconvert ${thomas_atlas}/${i}_${session_name}_scale-${scale}_parcellation.nii.gz [directory]/code/thomas_dMRI/labels/Scale${scale}_old_thomas_labels.txt [directory]/code/thomas_dMRI/labels/Scale${scale}_new_thomas_labels.txt ${thomas_atlas}/${i}_${session_name}_scale-${scale}_parcellation.nii.gz -force

	# Punch out any overlapping voxels of the new thomas atlas
	fslmaths ${thomas_atlas}/${i}_${session_name}_thomas_right.nii.gz -add ${thomas_atlas}/${i}_${session_name}_thomas_left.nii.gz -bin ${thomas_atlas}/thomasB.nii.gz;
	fslmaths ${thomas_atlas}/thomasB.nii.gz -mul -1 -add 1 ${thomas_atlas}/thomasI.nii.gz;	
	fslmaths ${thomas_atlas}/${i}_${session_name}_scale-${scale}_parcellation.nii.gz -mul ${thomas_atlas}/thomasI.nii.gz ${thomas_atlas}/${i}_${session_name}_scale-${scale}_parcellation.nii.gz;

	# Change the THOMAS label numbers to prevent clashes
	fslmaths ${thomas_atlas}/${i}_${session_name}_thomas_right.nii.gz -mul 1000 ${thomas_atlas}/thomas_rightX1000.nii.gz
	fslmaths ${thomas_atlas}/${i}_${session_name}_thomas_left.nii.gz -mul 1001 ${thomas_atlas}/thomas_leftX1001.nii.gz
	fslmaths ${thomas_atlas}/thomas_rightX1000.nii.gz -add ${thomas_atlas}/thomas_leftX1001.nii.gz ${thomas_atlas}/thomas_XB.nii.gz;
	fslmaths ${thomas_atlas}/${i}_${session_name}_scale-${scale}_parcellation.nii.gz -add ${thomas_atlas}/thomas_XB.nii.gz ${thomas_atlas}/${i}_${session_name}_scale-${scale}_parcellation_thomas.nii.gz

	#FIX THE LABEL NUMBERING
	labelconvert ${thomas_atlas}/${i}_${session_name}_scale-${scale}_parcellation_thomas.nii.gz [directory]/code/thomas_dMRI/labels/Scale${scale}_old_thomas_labels_thalamus.txt [directory]/code/thomas_dMRI/labels/Scale${scale}_new_thomas_labels_thalamus.txt ${thomas_atlas}/${i}_${session_name}_scale-${scale}_parcellation_thomas.nii.gz -force

	# MAKE THE CONNECTOMES
	
	# SIFT2

	reg_resample -flo ${thomas_atlas}/${i}_${session_name}_scale-${scale}_parcellation_thomas.nii.gz -ref ${diffusion_base}/${i}_${session_name}_nodif.nii.gz -aff $diffusion_base/${i}_${session_name}_t12diff.txt -res ${thomas_atlas}/${i}_${session_name}_scale-${scale}_diff_space_labels_thomas.nii.gz -inter 0
	
	tck2connectome -symmetric -tck_weights_in ${diffusion_base}/${i}_${session_name}_5M_sift.txt $diffusion_base/${i}_${session_name}_5M.tck ${thomas_atlas}/${i}_${session_name}_scale-${scale}_diff_space_labels_thomas.nii.gz ${thomas_atlas}/${i}_${session_name}_scale-${scale}_connectome_thomas_sift2.csv -force
	
	# Version corrected for node size
	tck2connectome -symmetric -scale_invnodevol -tck_weights_in ${diffusion_base}/${i}_${session_name}_5M_sift.txt $diffusion_base/${i}_${session_name}_5M.tck ${thomas_atlas}/${i}_${session_name}_scale-${scale}_diff_space_labels_thomas.nii.gz ${thomas_atlas}/${i}_${session_name}_scale-${scale}_connectome_thomas_sift2_scaled4nodesize.csv -force
	
	
	#FA connectome
	tcksample $diffusion_base/${i}_${session_name}_5M.tck $diffusion_base/${i}_${session_name}_fa.mif $diffusion_base/${i}_${session_name}_fa.csv -stat_tck mean
	
	tck2connectome -symmetric $diffusion_base/${i}_${session_name}_5M.tck ${thomas_atlas}/${i}_${session_name}_scale-${scale}_diff_space_labels_thomas.nii.gz ${thomas_atlas}/${i}_${session_name}_scale-${scale}_fa_connectome.csv -scale_file $diffusion_base/${i}_${session_name}_fa.csv -stat_edge mean
	

	done

#CLEAN

rm ${thomas_atlas}/temp*
rm ${thomas_atlas}/thomas*
rm ${thomas_atlas}/${i}_${session_name}_T1w.nii.gz

done
