spm12_NF_readme

To run the Neurofeedback Scripts some changes need to be done in spm's basis functions.
WARNING: Changes in the functions will become valid for all users who refer to the current spm version. It is recommended to copy the spm12 general folder, rename it to spm12_NF,
and perform changes exclusively in this new folder. If done as described above, the Neurofeedback Program will find the files it needs.

Description of changes:

1) Force spm to overwrite existing spm.mat files in the analysis directory

Go to file spm_run_fmri_spec.m

Comment out lines 31-39:

%-Ask about overwriting files from previous analyses
%--------------------------------------------------------------------------
%if exist(fullfile(pwd,'SPM.mat'),'file')
%    str = {'Current directory contains existing SPM file:',...
%           'Continuing will overwrite existing file!'};
%    if spm_input(str,1,'bd','stop|continue',[1,0],1,mfilename);
%        fprintf('%-40s: %30s\n\n',...
%            'Abort...   (existing SPM file)',spm('time'));
%        out = []; return
%    end
%end

2) Routine suggested by Tomás Slavícek to speed up dicom import. 

Go to file spm_dicom_header.m

This is how the original code looks like that needs adaptation:
 
function dict = readdict(P)
if nargin<1, P = 'spm_dicom_dict.mat'; end
 try
     dict = load(P);
catch
    fprintf('\nUnable to load the file "%s".\n', P);
    rethrow(lasterror);
end


Comment out the code above and copy-paste code below:

% Modified:
 
function dict = readdict(P)
global spm_dicom_dict_var
if nargin<1, P = 'spm_dicom_dict.mat'; end
try
    if ~isempty(spm_dicom_dict_var)
        dict = spm_dicom_dict_var;
    else
        dict = load(P);
    end
catch
    fprintf('\nUnable to load the file "%s".\n', P);
    rethrow(lasterror);
end


2) Download the gPPI toolbox from NITRC.
Unzip files to directory C:\Program Files\MATLAB
Make sure to copy matlab functions from gPPI package to folder C:\Program Files\MATLAB\PPPI. In order to work properly, functions must not be placed in a subdirectory within the PPPI folder.
There is a function included in the gPPI package called contains.m. Rename the function (e.g. PPPI_contains.m) or delete it. Otherwise this function will conflict with Matlab's contains.m function and the Neurofeedback program will not work.
Download the create_sphere_image functions provided on the gPPI download page on NITRC. Place the functions in the PPPI folder you created before.
Finally open the ms_Neurofeedback_GUI.m function and check that the path to your PPPI folder is correctly written in the addpath argument.

3) Download create_sphere function to SPM toolbox folder. Can be found as add-on to gPPI toolbox on NITRC.