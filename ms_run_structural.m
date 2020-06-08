function ms_run_structural(series, out_dir, allrois, dicom_dir)
% this function runs all the structural stuff

% out_dir = 'E:\\data\sub-99'; % remove!
% series = 2; % remove!

% change log:
% 2018/03/27: Copy grey matter image
% 2018/06/06: Apply inclusive GM mask to regions of interest (excluding control ROI)

% this is to update the gui
Status_text = findobj('Tag','Status_text');
Status_text.String = 'Starting structural procedure..';
%% load the settings
load([out_dir filesep 'config.mat']);
%% copy masks to dicom_dir for later normalization
nr_rois=2;
for i=1:nr_rois % copy masks to dicom_dir for later normalization || this code should be revised: allrois, roispec.srcimg and myrois are essentially the same. roispec.srcimg is used allover the following scripts
    copyfile(allrois{i}, dicom_dir);
    [~,fn, fne] = fileparts(allrois{i});
    myrois{i} = [fn fne];
    disp(myrois{i});
end

%% all structural stuff: dicom import, segmentation, nomralization etc.
cd(dicom_dir) % not sure if all the stuff should be saved here or in "data"
filter_regex = ['^001_', sprintf('%06d',series), '_.*'];
matlabbatch{1}.spm.util.dicom.data = cellstr(spm_select('FPList',dicom_dir,filter_regex));
matlabbatch{1}.spm.util.dicom.root = 'flat';
matlabbatch{1}.spm.util.dicom.outdir = {'.'};
matlabbatch{1}.spm.util.dicom.convopts.format = 'nii';
matlabbatch{1}.spm.util.dicom.convopts.icedims = 0;

dcmbatch = matlabbatch; 
clear matlabbatch;
spm_jobman('initcfg'); 
spm_jobman('run', dcmbatch);

% segment
spm_path = fileparts(which('spm'));

matlabbatch{1}.spm.spatial.preproc.channel.vols(1) = cellstr(spm_select('FPList','.','^s.*\.nii$')); 
matlabbatch{1}.spm.spatial.preproc.channel.biasreg = 0.001; 
matlabbatch{1}.spm.spatial.preproc.channel.biasfwhm = 60; 
matlabbatch{1}.spm.spatial.preproc.channel.write = [0 1]; 
matlabbatch{1}.spm.spatial.preproc.tissue(1).tpm = {[spm_path filesep 'tpm' filesep 'TPM.nii,1']}; 
matlabbatch{1}.spm.spatial.preproc.tissue(1).ngaus = 1; 
matlabbatch{1}.spm.spatial.preproc.tissue(1).native = [1 0]; 
matlabbatch{1}.spm.spatial.preproc.tissue(1).warped = [0 0]; 
matlabbatch{1}.spm.spatial.preproc.tissue(2).tpm = {[spm_path filesep 'tpm' filesep 'TPM.nii,2']}; 
matlabbatch{1}.spm.spatial.preproc.tissue(2).ngaus = 1; 
matlabbatch{1}.spm.spatial.preproc.tissue(2).native = [1 0]; 
matlabbatch{1}.spm.spatial.preproc.tissue(2).warped = [0 0]; 
matlabbatch{1}.spm.spatial.preproc.tissue(3).tpm = {[spm_path filesep 'tpm' filesep 'TPM.nii,3']}; 
matlabbatch{1}.spm.spatial.preproc.tissue(3).ngaus = 2; 
matlabbatch{1}.spm.spatial.preproc.tissue(3).native = [1 0]; 
matlabbatch{1}.spm.spatial.preproc.tissue(3).warped = [0 0]; 
matlabbatch{1}.spm.spatial.preproc.tissue(4).tpm = {[spm_path filesep 'tpm' filesep 'TPM.nii,4']}; 
matlabbatch{1}.spm.spatial.preproc.tissue(4).ngaus = 3; 
matlabbatch{1}.spm.spatial.preproc.tissue(4).native = [1 0]; 
matlabbatch{1}.spm.spatial.preproc.tissue(4).warped = [0 0]; 
matlabbatch{1}.spm.spatial.preproc.tissue(5).tpm = {[spm_path filesep 'tpm' filesep 'TPM.nii,5']}; 
matlabbatch{1}.spm.spatial.preproc.tissue(5).ngaus = 4; 
matlabbatch{1}.spm.spatial.preproc.tissue(5).native = [1 0]; 
matlabbatch{1}.spm.spatial.preproc.tissue(5).warped = [0 0]; 
matlabbatch{1}.spm.spatial.preproc.tissue(6).tpm = {[spm_path filesep 'tpm' filesep 'TPM.nii,6']}; 
matlabbatch{1}.spm.spatial.preproc.tissue(6).ngaus = 2; 
matlabbatch{1}.spm.spatial.preproc.tissue(6).native = [0 0]; 
matlabbatch{1}.spm.spatial.preproc.tissue(6).warped = [0 0]; 
matlabbatch{1}.spm.spatial.preproc.warp.mrf = 1; 
matlabbatch{1}.spm.spatial.preproc.warp.cleanup = 1; 
matlabbatch{1}.spm.spatial.preproc.warp.reg = [0 0.001 0.5 0.05 0.2]; 
matlabbatch{1}.spm.spatial.preproc.warp.affreg = 'mni'; 
matlabbatch{1}.spm.spatial.preproc.warp.fwhm = 0; 
matlabbatch{1}.spm.spatial.preproc.warp.samp = 3; 
matlabbatch{1}.spm.spatial.preproc.warp.write = [1 0]; % write deformation fields: [1 0] write inverse, [0 1] write forward (not needed)

segbatch = matlabbatch;

clear matlabbatch;
spm_figure('GetWin', 'Graphics');
spm_image('init', segbatch{1}.spm.spatial.preproc.channel.vols{1});

spm_jobman('run', segbatch);

iy_file = spm_select('FPList','.','^iy_s.*.nii$');

matlabbatch{1}.spm.spatial.normalise.write.subj.def = cellstr(iy_file); 
matlabbatch{1}.spm.spatial.normalise.write.subj.resample = cellstr(myrois)';
matlabbatch{1}.spm.spatial.normalise.write.woptions.bb = [-78 -112 -70 
                                                          78 76 85]; 
matlabbatch{1}.spm.spatial.normalise.write.woptions.vox = [3 3 3]; 
matlabbatch{1}.spm.spatial.normalise.write.woptions.interp = 5; 
matlabbatch{1}.spm.spatial.normalise.write.woptions.prefix = 'w';

normmaskbatch = matlabbatch;
clear matlabbatch;

spm_jobman('run', normmaskbatch);


%% Mask ROIs with grey matter mask

matlabbatch{1}.spm.spatial.coreg.write.ref = {['w' myrois{1}]}; 
matlabbatch{1}.spm.spatial.coreg.write.source = {spm_select('FPList','.','^c1s.*192.*\.nii$')}; % ... We now need to jiggle the grey matter image and coregister and reslice to subject space
matlabbatch{1}.spm.spatial.coreg.write.roptions.interp = 0;
matlabbatch{1}.spm.spatial.coreg.write.roptions.wrap = [0 0 0];
matlabbatch{1}.spm.spatial.coreg.write.roptions.mask = 0;
matlabbatch{1}.spm.spatial.coreg.write.roptions.prefix = 'r';

coregbatch = matlabbatch;
clear matlabbatch;

spm_jobman('run', coregbatch);

% Mask anatomical regions of interest with grey matter inclusive mask:
% Amygdala
matlabbatch{1}.spm.util.imcalc.input = {
                                        spm_select('FPList','.','^rc1s.*192.*\.nii$')
                                        ['w' myrois{1}]
                                        };
matlabbatch{1}.spm.util.imcalc.output = ['imw' myrois{1} ]; % append "im" indicating inclusive mask
matlabbatch{1}.spm.util.imcalc.outdir = {''};
matlabbatch{1}.spm.util.imcalc.expression = '(i1>0).*i2';
matlabbatch{1}.spm.util.imcalc.var = struct('name', {}, 'value', {});
matlabbatch{1}.spm.util.imcalc.options.dmtx = 0;
matlabbatch{1}.spm.util.imcalc.options.mask = 0;
matlabbatch{1}.spm.util.imcalc.options.interp = 1;
matlabbatch{1}.spm.util.imcalc.options.dtype = 4;

imcalcbatch = matlabbatch;
clear matlabbatch;

spm_jobman('run', imcalcbatch);

%% illustrate the result
spm_figure('GetWin', 'Graphics');
spm_clf;
H = spm_orthviews('Image', segbatch{1}.spm.spatial.preproc.channel.vols{1});
for ix=1:length(myrois)
%     ims(ix) = cellstr(spm_select('FPList','.',['^w' roispec{ix}.srcimg]));
    ims(ix) = cellstr(spm_select('FPList','.',['^' roispec{ix}.srcimg]));
end
for i=1:numel(ims)
    col = zeros(1,3);
    col(mod(i,3)+1) = 1;
    spm_orthviews('AddColouredImage', H, ims{i}, col);
end
spm_orthviews('Redraw');

%% copy the normalized ROIs into the "data" (outputdir) folder
for i=1:numel(ims)
    copyfile(ims{i}, out_dir);
end

copyfile(imcalcbatch{1}.spm.util.imcalc.input{1},[out_dir filesep 'rc1s_gm.nii']); % Move the realigned and resliced grey matter image to data folder, will be used for beta-feedback analysis
copyfile(segbatch{1}.spm.spatial.preproc.channel.vols{1},[out_dir filesep 's',subjid,'_structural.nii']); % here we just put the structural into the "data"-folder

%% tell the user that now the functional experiment can start
Status_text.String = 'Starting structural procedure.. done';
Status_text.String = char(Status_text.String, 'Everything should be ready for functional run.');