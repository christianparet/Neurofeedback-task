%% Run this script after manual reorientation of structural from current subject folder
% nifti image needed

% segment
%f = spm_select;
matlabbatch{1}.spm.spatial.preproc.data = cellstr(spm_select('FPList','.','^s.*\.nii$')); 
matlabbatch{1}.spm.spatial.preproc.output.GM = [0 0 1];
matlabbatch{1}.spm.spatial.preproc.output.WM = [0 0 1];
matlabbatch{1}.spm.spatial.preproc.output.CSF = [0 0 0];
matlabbatch{1}.spm.spatial.preproc.output.biascor = 1;
matlabbatch{1}.spm.spatial.preproc.output.cleanup = 0;
spmdir = spm('Dir');

matlabbatch{1}.spm.spatial.preproc.opts.tpm = {
                                               [spmdir '/tpm/grey.nii']
                                               [spmdir '/tpm/white.nii']
                                               [spmdir '/tpm/csf.nii']
                                               };
matlabbatch{1}.spm.spatial.preproc.opts.ngaus = [2
                                                 2
                                                 2
                                                 4];
matlabbatch{1}.spm.spatial.preproc.opts.regtype = 'mni';
matlabbatch{1}.spm.spatial.preproc.opts.warpreg = 1;
matlabbatch{1}.spm.spatial.preproc.opts.warpco = 25;
matlabbatch{1}.spm.spatial.preproc.opts.biasreg = 0.0001;
matlabbatch{1}.spm.spatial.preproc.opts.biasfwhm = 60;
matlabbatch{1}.spm.spatial.preproc.opts.samp = 3;
matlabbatch{1}.spm.spatial.preproc.opts.msk = {''};

segbatch = matlabbatch;
clear matlabbatch;
spm_figure('GetWin', 'Graphics');
spm_image('init', segbatch{1}.spm.spatial.preproc.data{1});

spm_jobman('run', segbatch);

% normalize structural to mni
snfile = spm_select('FPList','.','^s.*_seg_sn\.mat$');

matlabbatch{1}.spm.spatial.normalise.write.subj.matname = cellstr(snfile);
matlabbatch{1}.spm.spatial.normalise.write.subj.resample = segbatch{1}.spm.spatial.preproc.data;

matlabbatch{1}.spm.spatial.normalise.write.roptions.preserve = 0;
matlabbatch{1}.spm.spatial.normalise.write.roptions.bb = [-78 -112 -50
                                                          78 76 85];
matlabbatch{1}.spm.spatial.normalise.write.roptions.vox = [1 1 1];
matlabbatch{1}.spm.spatial.normalise.write.roptions.interp = 0;
matlabbatch{1}.spm.spatial.normalise.write.roptions.wrap = [0 0 0];
matlabbatch{1}.spm.spatial.normalise.write.roptions.prefix = 'w';

normmaskbatch = matlabbatch;
clear matlabbatch;
spm_jobman('run', normmaskbatch);

% next move masks to native space
snfile = spm_select('FPList','.','^s.*_seg_inv_sn\.mat$');

matlabbatch{1}.spm.spatial.normalise.write.subj.matname = cellstr(snfile);
matlabbatch{1}.spm.spatial.normalise.write.subj.resample = myrois;

matlabbatch{1}.spm.spatial.normalise.write.roptions.preserve = 0;
matlabbatch{1}.spm.spatial.normalise.write.roptions.bb = [-78 -112 -50
                                                          78 76 85];
matlabbatch{1}.spm.spatial.normalise.write.roptions.vox = [3 3 3];
matlabbatch{1}.spm.spatial.normalise.write.roptions.interp = 0;
matlabbatch{1}.spm.spatial.normalise.write.roptions.wrap = [0 0 0];
matlabbatch{1}.spm.spatial.normalise.write.roptions.prefix = 'w';

normmaskbatch = matlabbatch;
clear matlabbatch;


spm_jobman('run', normmaskbatch);

spm_figure('GetWin', 'Graphics');
spm_clf;
H = spm_orthviews('Image', segbatch{1}.spm.spatial.preproc.data{1});

ims(1) = cellstr(spm_select('FPList','.','^wRight Amygdala.*\.(nii|img)$'));
ims(2) = cellstr(spm_select('FPList','.','^wrect.*\.(nii|img)$')); 


for i=1:numel(ims)
    col = zeros(1,3);
    col(mod(i,3)+1) = 1;
    spm_orthviews('AddColouredImage', H, ims{i}, col);
end
spm_orthviews('Redraw');
