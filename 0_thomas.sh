#!/bin/sh

# Define group , e.g. GROUP = SEEG or GROUP = resections or GROUP = controls
read -p 'Group: ' GROUP

# Define session name 
read -p 'Session: ' session_name

# LOOP THROUGH SUBJECTS

sublist=pwd

for i in sub*; do

echo $i

# SET THE BASES
t1_base=[DIRECTORY]/thomas_dMRI/$GROUP/input/source_data/${i}/$session_name/anat
mkdir [DIRECTORY]/thomas_dMRI/$GROUP/output/thomas
mkdir [DIRECTORY]/thomas_dMRI/$GROUP/output/thomas/${i}
mkdir [DIRECTORY]/thomas_dMRI/$GROUP/output/thomas/${i}/${session_name}/
thomas_base=[DIRECTORY]/thomas_dMRI/$GROUP/output/thomas/${i}/${session_name}


# COPY T1w to THOMAS FOLDER
cp $t1_base/${i}_${session_name}_T1w.nii.gz $thomas_base/${i}_${session_name}_T1w.nii.gz

# THOMAS demands to be in the directory where the T1w is...
cd $thomas_base

# RUN THOMAS
docker run -v ${PWD}:${PWD} -w ${PWD} --user $(id -u):$(id -g) --rm -t anagrammarian/thomasmerged bash -c "hipsthomas_csh -i ${i}_${session_name}_T1w.nii.gz -t1"

# RE-ORGANISE / TIDY FILES
cp left/thomasfull.nii.gz ${i}_${session_name}_thomas_left.nii.gz
cp right/thomasrfull.nii.gz ${i}_${session_name}_thomas_right.nii.gz
rm -r right left temp tempr

# Move back to the subject list
cd ${sublist}

done


