function [outputdir, allrois] = SetExpProps_brainboost(dicom_dir)
% this function is used to set and save the general setup of a
% study/experiment

% CP, 20200608: added variable ITI

%%Creates BPD_test_data/pa**** folder under the Home directory (e.g. /clusterdata1/BPD_test_data/pa1060/), modified by
%%Charles on 11/15/2019
[p,n,subjid]=fileparts(dicom_dir);
subjid=erase(subjid,'.');
homedir = p; % define homedir; last filesep needed?
%% adapt outputdir for site
outputdir=[homedir '/data' filesep subjid filesep]; % output directory
%%
if ~exist(outputdir,'dir'); mkdir(outputdir); end
clear p n loc

%% expected MPRAGE settings
expMPRAGEseries = 2; expMPRAGEslices = 192;
%% expected Functional series
expFUNCTseries=4;

%% set paradigm parameters
% define duration of experimental blocks/trials (unit: TR)
paradigm.wait.name = {'wait'}; 
paradigm.WaitBegin.duration = 24;
paradigm.WaitEnd.duration = 3; % additional TRs after last TR of last trial
paradigm.cond(1).name = {'DOWN_trial'};
paradigm.cond(1).duration = 45;
paradigm.cond(2).name = {'DOWN_instruct'};
paradigm.cond(2).duration = 1;
paradigm.cond(3).name = {'VIEW_trial'};
paradigm.cond(3).duration = 18;
paradigm.cond(4).name = {'VIEW_instruct'};
paradigm.cond(4).duration = 1;
paradigm.rest.name = {'rest'};
paradigm.rest(1).duration = 6; % added by CP, 20200608
paradigm.rest(2).duration = 8;
paradigm.rest(3).duration = 10;
paradigm.rest(4).duration = 12;
% if more blocks are needed continue with that scheme until variable paradigm.rest has size of block repetitions

block_repetitions = 4; % Brainboost: 4
randvar1 = randperm(block_repetitions); % added by CP, 20200608
randvar2 = randperm(block_repetitions);

for i=1:block_repetitions
    Block(i) = [repmat(paradigm.cond(4).name,[paradigm.cond(4).duration 1]); ...
        repmat(paradigm.cond(3).name,[paradigm.cond(3).duration 1]); ...
        repmat(paradigm.rest.name,[paradigm.rest(randvar1(i)).duration 1]);... % changed by CP, 20200608
        repmat(paradigm.cond(2).name,[paradigm.cond(2).duration 1]); ...
        repmat(paradigm.cond(1).name,[paradigm.cond(1).duration 1]); ...
        repmat(paradigm.rest.name,[paradigm.rest(randvar2(i)).duration 1])]; % changed by CP, 20200608
end

experiment_names = [repmat(paradigm.wait.name,[paradigm.WaitBegin.duration 1]);...
    repmat(paradigm.rest.name,6); ...
    Block(1); Block(2); Block(3); Block(4)]; % increase if more blocks % changed by CP, 20200608

% Brainboost: transfer experiment is separate from nf training; therefore all trials are training trials
experiment_type = [repmat(paradigm.wait.name,[paradigm.WaitBegin.duration 1]);...
    repmat({'training'},[length(Block)*block_repetitions+paradigm.rest.duration 1])];

experiment_info = repmat({'none'},[length(experiment_names) 1]);

% experiment:
% 1st colomn: Condition names
% 2nd colomn: transfer (no feedback) or training (continuous feedback)
experiment = [experiment_names experiment_type experiment_info];
experiment(end) = {'end_experiment'};%the signal expected by Presentation program to terminate the run.

% for figure
% paradigm.Scheme = [zeros(paradigm.WaitBegin.duration,1); ones(length(Block)*block_repetitions+paradigm.rest.duration,1); zeros(paradigm.WaitEnd.duration,1)];
% Modified by Charles
paradigm.Scheme = zeros(length(experiment_type),1);
trial_ind=deblank(char(experiment_names))=='Down_instruct';
paradigm.Scheme(trial_ind(:,1))=1; 
%% figure set-up
screen = [1600 900]; % resolution, for graphics; adapt to screen dimensions

panel_brain_ratio = 566.67/816.94;
height_panel_brain = screen(2)*2/3;
width_panel_brain = height_panel_brain*panel_brain_ratio;
pos_panel_brain = [screen(1)-width_panel_brain 0 width_panel_brain height_panel_brain];
pos_panel_timecourse = [screen(1)/4 screen(2)*2/4 (screen(1))*2/4 (screen(2))/4];

%% the following are the settings for the functional run
%% adapt mask_dir for site
mask_dir = [homedir '/Masks'];  
%%
allrois = {[mask_dir '/Right Amygdala 25.nii'],...
           [mask_dir '/rect.nii']}; 
% used for the server/functional run
timeout = 600;
nrROIs = 2; % needed anymore? if removed, change structure S below
TR = 2;
FeedbackScaleMethod = 'GenericScale'; % GenericScale or AdaptiveScale

roispec{1}.srcimg = 'imwRight Amygdala 25.nii'; % used in ms_run_functional_kalman_detrend
roispec{2}.srcimg = 'wrect.nii'; % used in ms_run_functional_kalman_detrend

% realign options (not checked) % used in ms_run_functional_kalman_detrend
rflags.quality = 0.5; % decrease if needed, default is 0.9
rflags.fwhm = 5;
rflags.rtm = 0;
rflags.interp =  1; %trilinear
rflags.sep = 8; % increase if possible, default is 4
rflags.graphics = 0;

% reslice options (not checked) % used in ms_run_functional_kalman_detrend
rsflags = struct('mask', false,...
                 'mean', false,...
                 'interp', 2,... % spline order (0 = nearest neighbour, 1=trilinear, 2 = 2nd order bspline 
                 'which', 1,...
                 'wrap', [0; 0; 0],...
                 'prefix', 'r');
            
% coregister options
corflags = struct('graphics', 0,...
                  'sep', 3); % 5
                         
% Filter settings % used in ms_run_functional_kalman_detrend
% Kalman covariance matrices and threshold definition from Yuri Koushs Script "test_feedbackSP_subsequentROIs.m"
S.Q = 0; 
S.P = S.Q; 
S.x = 0;
S(1:nrROIs) = S;
fposDer = zeros(nrROIs,1);
fnegDer = zeros(nrROIs,1);

% save experiment settings
rtconfig = struct('dicom_dir', dicom_dir,...
                    'timeout', timeout,...
                    'port', 8082); %8082
                
%% jump into the outputdir and save everything as config.mat
cd(outputdir)
save config
fprintf('PreRun: Saved settings in config.mat in %s\n', outputdir)