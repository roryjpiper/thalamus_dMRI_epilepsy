# Lausanne/THOMAS dMRI / Structural Connectivity Pipeline

This is an MRI and diffusion MRI (dMRI) processing pipeline that generates matrices of structural connectivity per subject.

The pipeline parcellates the brain in subject native space using the Lausanne atlas (three options of spatial resolution) via Freesurfer (https://surfer.nmr.mgh.harvard.edu/) and the THOMAS thalamic atlas (https://github.com/thalamicseg/hipsthomasdocker). 

Tractography is processed using MRTRIX3 (https://www.mrtrix.org/).

Processing steps are organised into the following scripts:
* THOMAS atlas parcellation [0_thomas.sh]
* Freesurfer parcellation [1_freesurfer.sh]
* Freesurfer refinement (control pointing) [2_freesurfer_refine.sh]
* Conversion to Lausanne atlas [3_fs_2_lausanne.sh] (add the .annot files to fs_average folder)
* Diffusion preprocessing [4_diffusion_preproc.sh]
* Tractography processing [5_tractography.sh]
* Connectome construction [6_connectome.sh]

For each script, be sure to change the '[directory]' to the relevant directory on your machine. 
