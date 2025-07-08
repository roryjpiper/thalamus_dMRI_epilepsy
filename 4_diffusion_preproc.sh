#!/bin/bash

# arguments not required!

# dwi       - multishell diffusion dataset
# dwi_negpe - negative phase-encoded b0 image

# Define group , e.g. GROUP = SEEG or GROUP = resections or GROUP = controls
read -p 'Group: ' GROUP

# Define session name 
read -p 'Session: ' session_name

# DEPENDENCIES
export ANTSPATH=/home/[DIRECTORY]/software/install/bin/
export PATH=${ANTSPATH}:$PATH


for i in sub-*; do 
	
	echo ${i}
	
	dwi_path=[DIRECTORY]/thomas_dMRI/${GROUP}/input/source_data/${i}/${session_name}/dwi
	mkdir [DIRECTORY]/thomas_dMRI/${GROUP}/output/dwi/${i}/
	mkdir [DIRECTORY]/thomas_dMRI/${GROUP}/output/dwi/${i}/${session_name}
	output_path=[DIRECTORY]/thomas_dMRI/${GROUP}/output/dwi/${i}/${session_name}
	
	fslroi $dwi_path/${i}_${session_name}_dir-AP_dwi.nii.gz $output_path/${i}_${session_name}_b0.nii.gz 0 1
	cp $dwi_path/${i}_${session_name}_dir-PA_dwi.nii.gz $output_path/${i}_${session_name}_b0_flip.nii.gz
	
   
	fslmerge -t $output_path/${i}_${session_name}_b0s_all.nii.gz $output_path/${i}_${session_name}_b0.nii.gz $output_path/${i}_${session_name}_b0_flip.nii.gz
	mkdir $output_path/mrtrix

    
	# Add in denoising step
    
	mrconvert $dwi_path/${i}_${session_name}_dir-AP_dwi.nii.gz $output_path/${i}_${session_name}_dwi_raw.mif -force
	dwidenoise $output_path/${i}_${session_name}_dwi_raw.mif $output_path/${i}_${session_name}_dwi_denoised.mif -noise $output_path/${i}_${session_name}_noise.mif -force
	
	dwifslpreproc -rpe_pair -se_epi $output_path/${i}_${session_name}_b0s_all.nii.gz -pe_dir AP -fslgrad $dwi_path/${i}_${session_name}_dir-AP_dwi.bvec $dwi_path/${i}_${session_name}_dir-AP_dwi.bval -eddy_options "--repol " $output_path/${i}_${session_name}_dwi_denoised.mif -eddyqc_all $output_path/mrtrix/eddy $output_path/mrtrix/${i}_${session_name}_dndwi.mif -force

	# Other preprocessing steps

	mrconvert $output_path/mrtrix/${i}_${session_name}_dndwi.mif  $output_path/mrtrix/${i}_${session_name}_data.nii.gz -stride 1,2,3,4 -force
	fslroi  $output_path/mrtrix/${i}_${session_name}_data.nii.gz  $output_path/mrtrix/${i}_${session_name}_nodif.nii.gz 0 1

	bet  $output_path/mrtrix/${i}_${session_name}_nodif.nii.gz  $output_path/mrtrix/${i}_${session_name}_brain -m -n -f 0.3
	mrconvert $output_path/mrtrix/${i}_${session_name}_brain_mask.nii.gz $output_path/mrtrix/${i}_${session_name}_mask.mif -force

	# Add bias correction step
    
	dwibiascorrect ants -mask $output_path/mrtrix/${i}_${session_name}_mask.mif $output_path/mrtrix/${i}_${session_name}_dndwi.mif $output_path/mrtrix/${i}_${session_name}_dnbcdwi.mif -force
	
	dwi2tensor $output_path/mrtrix/${i}_${session_name}_dnbcdwi.mif -mask $output_path/mrtrix/${i}_${session_name}_mask.mif $output_path/mrtrix/${i}_${session_name}_dt.mif -force

	# Get tensors
    
	tensor2metric $output_path/mrtrix/${i}_${session_name}_dt.mif -fa $output_path/mrtrix/${i}_${session_name}_fa.mif -adc $output_path/mrtrix/${i}_${session_name}_md.mif -vector $output_path/mrtrix/${i}_${session_name}_ev.mif -force
   
	dwi2response dhollander $output_path/mrtrix/${i}_${session_name}_dnbcdwi.mif $output_path/mrtrix/${i}_${session_name}_wm_response.txt $output_path/mrtrix/${i}_${session_name}_gm_response.txt $output_path/mrtrix/${i}_${session_name}_csf_response.txt -nocleanup -force
	dwi2fod msmt_csd -mask $output_path/mrtrix/${i}_${session_name}_mask.mif $output_path/mrtrix/${i}_${session_name}_dnbcdwi.mif $output_path/mrtrix/${i}_${session_name}_wm_response.txt $output_path/mrtrix/${i}_${session_name}_wm.mif $output_path/mrtrix/${i}_${session_name}_gm_response.txt $output_path/mrtrix/${i}_${session_name}_gm.mif $output_path/mrtrix/${i}_${session_name}_csf_response.txt $output_path/mrtrix/${i}_${session_name}_csf.mif -force
	
	# cleanup - remove redundant heavy files
	#rm $output_path/mrtrix/${i}_${session_name}_data.nii.gz
	#rm $output_path/${i}_${session_name}_dwi_raw.mif
	#rm $output_path/${i}_${session_name}_dwi_denoised.mif
	#rm $output_path/mrtrix/${i}_${session_name}_dndwi.mif
	#rm $output_path/mrtrix/${i}_${session_name}_dnbcdwi.mif
    
done
