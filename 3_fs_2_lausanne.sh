## Code needed to generate extra parcellations

# Need the following in the same location as the script

# fsaverage - a folder which stores all the information about the additional parcellations
# subjid.txt - txt file that stores the filepath of freesurfer folders of the subject you want to run

#--
#Set up FREESURFER PATHS (can remove if set up in terminal)
export FREESURFER_HOME=[directory]/software/freesurfer
source $FREESURFER_HOME/SetUpFreeSurfer.sh

#alias ll='ls -lasG'

## Find where this "genstats.sh" code is located for
#BASEDIR=$(dirname "$0")

# Cd into the location where this bit of code is stored

BASEDIR='[directory]/code/thomas_dMRI/3_fs_2_lausanne'
cd $BASEDIR

echo "set up complete"

##ƒor every file path stored in subjid.txt
for path in $(cat subjid.txt);do

    # Use the filepath to get an id name ...
    id=$( basename "$path")
    subjid=$id

    echo $subjid

    # ... and where the file is located
    datadir=$(echo $(dirname $path))

    echo $datadir
    
    echo $BASEDIR"/fsaverage/"

    # For this code the fsaverage file needed to be the same folder as where the freesurfer folder is stored
    #MAC
    #cp -R $BASEDIR"/fsaverage/" $datadir"/fsaverage/"
    #LINUX
    cp -r $BASEDIR"/fsaverage/" $datadir"/fsaverage/"
   


    mkdir $datadir/$subjid/stats/
    
    #Set up for freesurfer
    SUBJECTS_DIR=$datadir
    
    cd $SUBJECTS_DIR 
    #ln -s $FREESURFER_HOME/subjects/fsaverage fsaverage
    
    # Create an array that contains the names of the new parcellations we would like to use.
    declare -a arr=("500.aparc" "myaparc_36" "myaparc_60" "myaparc_125" "myaparc_250" "HCP-MMP1")
    
    # For each new parcellation scheme
    for i in "${arr[@]}";do
	
        ATLAS=$i
        echo $ATLAS
    
        # resamples right hemi-sphere CorticalSurface
        mri_surf2surf --srcsubject fsaverage --trgsubject $subjid --hemi rh --sval-annot fsaverage/label/rh.$ATLAS.annot --tval $datadir/$subjid/label/rh.$ATLAS.annot

cp $SUBJECTS_DIR/$subjid/surf/rh.pial.T1 /$SUBJECTS_DIR/$subjid/surf/rh.pial

#mris_anatomical_stats -a $datadir/$subjid/label/rh.$ATLAS.annot -f $datadir/$subjid/stats/rh.$ATLAS.stats $subjid rh &

	# resamples left hemi-sphere CorticalSurface
        mri_surf2surf --srcsubject fsaverage --trgsubject $subjid --hemi lh --sval-annot $datadir/fsaverage/label/lh.$ATLAS.annot --tval $datadir/$subjid/label/lh.$ATLAS.annot

cp $SUBJECTS_DIR/$subjid/surf/lh.pial.T1 /$SUBJECTS_DIR/$subjid/surf/lh.pial

#mris_anatomical_stats -a $datadir/$subjid/label/lh.$ATLAS.annot -f $datadir/$subjid/stats/lh.$ATLAS.stats $subjid lh &
        
        
        #Maps the cortical labels from the automatic cortical parcellation (aparc) to the automatic segmentation volume (aseg).
        
	mri_aparc2aseg --s $subjid --annot $ATLAS --o $datadir/$subjid/mri/$ATLAS.mgz &


done

done
