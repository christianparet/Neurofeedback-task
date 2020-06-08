function run_functional_brainboost(series_number, out_dir, ax)

% addpath('C:\Program Files\MATLAB\spm12_NF') % See spm12_NF_readme ! remove
% addpath('S:\AG_Selfregulation\Projects\BrainBoost\realtime program') % remove
% 
% clear; % remove!
% out_dir = 'C:\data\EFP23POST'; % remove!
% series_number = 9; % remove!

% This function "works" completely in the output directory!
cd(out_dir);
%% IF RUNNING SUBJECT change to dryrun = 0; and fakeServer = 0; !!!
dryrun = 1; fakeServer = 0;
if dryrun || fakeServer
    answer = questdlg('You run a "dry run" and/or a fake server! Is that okay?', 'Check Settings', 'It''s okay', 'Change that!', 'Change that!');
    if contains(answer,'Change'); edit(mfilename); return; end
end
%% load the settings
load([out_dir filesep 'config.mat']);

%% start the functional stuff
spm('defaults','fmri');
spm_jobman('initcfg');

try
    dicom_dir = rtconfig.dicom_dir;
catch
    disp('error in configuration structure');
    return
end

% initiate some variables
V = [];
current_image_count = 1;
experiment_count = 0; 
sigtarget.YData = [];
sigcontrolroi.YData = [];
sigdiff.YData = [];
protocol.table = [];
protocol.events = {'condition',...
                   'type',...
                   'functional image (fn)',...
                   'fn arrival time',...
                   'preprocessing duration',...
                   'ROI1 raw',...
                   'ROI2 raw',...
                   'ROI1 filt',...
                   'ROI2 filt',...
                   'ROI1 filt detrend',...
                   'ROI2 filt detrend',...
                   'feedback',...
                   'duration of model estimation'};                 

%% Figure
update_orthview_new(['s',subjid,'_structural.nii'], roispec);
s=gcf;
set(s,'OuterPosition',pos_panel_brain)

%% draw it in the paradigm preview
hold(ax,'on')

sigtarget=plot(0,0,'r','LineWidth',2, 'Parent',ax);
sigcontrolroi=plot(0,0,'g','LineWidth',2, 'Parent',ax);
sigdiff=plot(0,0,'b-','LineWidth',2, 'Parent',ax);
try
    for ix=length(ax.Children):-1:4
        try
            le{ix}=char(ax.Children(ix).DisplayName);
        catch
            le{ix}=[];
        end
    end
    le(1:3)=[]; ole=char(flip(le));
    legend(ax, char(ole, 'target ROI','control ROI','delta'),'Location','northwestoutside')
    catch
    legend(ax,'rest','feedback', 'target ROI','control ROI','delta','Location','northwestoutside')
end
hold(ax,'off')
pause(.025);

%% TC, needs Instrument Control Toolbox to work
if (rtconfig.port > 0)
    tc = tcpip('0.0.0.0', rtconfig.port, 'NetworkRole', 'server');
    set(tc,'InputBufferSize', 4096);
    set(tc,'OutputBufferSize', 4096);
    set(tc,'Timeout', 30);
    fprintf(1, 'waiting for network connection\n');
    if ~fakeServer; fopen(tc); end
    fprintf(1, 'network open\n');
else
    fprintf('no network, running\n');
end

%% Real-time fMRI
run_start_time = clock;
volfile_present_time = run_start_time;
time_img = clock;

while (1)
    expected_fn = [dicom_dir '/001_' sprintf('%06d',series_number), '_', sprintf('%06d',current_image_count), '.dcm'];
    
    if dryrun; pause(0.1); end% dry run
    
    lastwarn('');
    
    %     if (exist(expected_fn, 'file'))
    jexpected_fn=java.io.File(expected_fn);
    if (jexpected_fn.exists)
        
        event_list = cell(1,11);
        
        event_list{1} = expected_fn;
        event_list{2} = clock;
        tic
        
        if dryrun
            jexpected_online=java.io.File([dicom_dir '/NotAFile.txt']); % some random file name
        else
            jexpected_online=java.io.File([dicom_dir '/001_' sprintf('%06d',series_number), '_', sprintf('%06d',current_image_count+1), '.dcm']); % check whether next image already exists
        end         
        
        if experiment_count > 0 && jexpected_online.exists % in case of irregular timing the catch up routine ensures that feedback comes from most recent image received
            catch_up = 1;
            fprintf('\nCatch up to next image'); 
            fprintf('\nProcessing image %d', current_image_count);
        else
            experiment_count = experiment_count + 1; % only increase count when paradigm continues
            if contains(experiment{experiment_count,3},'end_experiment')
                disp('Experiment ends.');
                if rtconfig.port > 0
                    try
                        fprintf(tc, 'end '); % Stop Presentation program
                    catch
                        fprintf(2, 'error writing feedback to tcp socket\n');
                    end
                    fclose(tc);
                end
                x = clock;
                xs = sprintf('%d-%d-%d-%d-%d-%2.0f',x);
                save([subjid '_protocol_' xs], 'protocol');
                break;
            else
                catch_up = 0;
                fprintf('\n\n------------- +++++++++++ ------------- +++++++++++ -------------\nImage count: %d\n', current_image_count);
            end
        end    
         
        pause(0.025); % needed to update figure

        try
            hdr = spm_dicom_headers(expected_fn);
            out = spm_dicom_convert(hdr, 'all', 'flat', 'nii');
        catch
            disp('dicom read error');
            continue;
        end
        msg =  lastwarn;
        if (~strcmp(msg, ''))
            disp('dicom read warning');
            continue;
        end
        if current_image_count == 1
            first_image = out.files{1};
            update_figure = 1;
            
            % coregistration
            coreg_params_disp = spm_coreg(['s',subjid,'_structural.nii'],first_image,corflags);
            M = inv(spm_matrix(coreg_params_disp));
            MM = spm_get_space(first_image);
            spm_get_space(deblank(first_image), M*MM);
            fprintf(2,'\ncoregistered by x,y,z (mm): ');
            fprintf(2,'%4.1f ', coreg_params_disp(1:3));
            fprintf('\n');
            
        else
            update_figure = 0;
            
            % realign
            spm_realign(strvcat(first_image, out.files{1}), rflags); 
            spm_reslice(strvcat(first_image, out.files{1}), rsflags);
            
            try
                [~,rpfile,~]=fileparts(first_image);
                rpfile = fullfile(subjdir,['rp_',rpfile,'.txt']);
                realign_params_temp=dlmread(rpfile);
                realign_params_disp(end+1,:)=realign_params_temp(2,:);
                fprintf('\nrelative momvement  x,y,z (mm):  ')
                fprintf('%4.1f  ', realign_params_disp(end,1:3)-realign_params_disp(end-1,1:3)); %5.2f
                fprintf('\n')
            end
        end
        
        if update_figure
            update_orthview_new(first_image, roispec);
            update_figure = 0;
        end
        
        event_list{1,3} = toc;
        
        try
            if current_image_count == 1
                fname = out.files{1};
            else
                [p,fn,~] = fileparts(out.files{1});
                fname = [p '/r' fn '.nii'];
            end
            [outr,~] = SNiP_tbxvol_extract_fast(fname , roispec, 'none');
        catch
            disp('extract error');
            continue;
        end
        
        %% Filter signal
        % Method adopted from Yuri Koush
        for roi=1:2
            
            V(current_image_count, roi) = mean(outr{roi});
            
            if current_image_count == 0
                tmp_std = 0;
            elseif current_image_count < 3
                tmp_std = std(V(1:current_image_count,roi))';
            else
                tmp_std = std(V(1:current_image_count,roi))';
            end
            
            if TR == 1
                % lambda = R/Q = 4 : approx. equivalent to the Butterworth Fc = 0.155 Hz, TR = 1s, Fs = 1Hz
                S(roi).Q = tmp_std.^2;
                S(roi).R = 4*S(roi).Q;
                Th_K(roi) = .9*tmp_std;
            elseif TR == 2
                % lambda = R/Q = 1.95 : approx. equivalent to the Butterworth Fc = 0.106 Hz, TR = 2s, Fs = 0.5Hz
                S(roi).Q = tmp_std.^2;
                S(roi).R = 1.95*S(roi).Q; % .001 for despiking only
                Th_K(roi) = .9*tmp_std;   %   2   for despiking only
            end
            
            [out_kalm_Sample(current_image_count,roi), S(roi), fposDer(roi), fnegDer(roi)] = kalman_spike(Th_K(roi), V(current_image_count,roi), S(roi), fposDer(roi), fnegDer(roi));
            
        end
        
        event_list{4} = V(end,1);
        event_list{5} = V(end,2);

        event_list{6} = out_kalm_Sample(end,1);
        event_list{7} = out_kalm_Sample(end,2);
        
        if current_image_count > paradigm.WaitBegin.duration
            detrend_out_kalm_Sample = detrend(out_kalm_Sample(paradigm.WaitBegin.duration+1:end,:));
            sigtarget.YData = [sigtarget.YData detrend_out_kalm_Sample(end,1)];
            sigcontrolroi.YData = [sigcontrolroi.YData detrend_out_kalm_Sample(end,2)];
            event_list{8} = detrend_out_kalm_Sample(end,1);
            event_list{9} = detrend_out_kalm_Sample(end,2);
        else
            sigtarget.YData = [sigtarget.YData 0];
            sigcontrolroi.YData = [sigcontrolroi.YData 0];
        end
        
        sigtarget.XData = 1:length(sigtarget.YData);

        sigcontrolroi.XData = 1:length(sigcontrolroi.YData);

        sigdiff.XData = sigtarget.XData;
        sigdiff.YData = sigtarget.YData - sigcontrolroi.YData;
                
        if ~catch_up
            
            %% Calculate local mean and SD 
            % Routine used if feedback is scaled relative to baseline
            if contains(experiment{experiment_count,3},'end_block')
                % Determine local mean/baseline and SD, based on the previous block, to be used during the next UP/DOWN feedback block
                samples = detrend_out_kalm_Sample(begin_sampling:end-1,1) - detrend_out_kalm_Sample(begin_sampling:end-1,2); % Take all samples of previous block into account. Subtract ROI2 from ROI1
                local_mean = 0; % alternative: local_mean = mean(samples); 0 standardizes to global mean and is not dependend on performance during last block or spontaneous activation during rest
                local_SD = std(samples);
                previous_thermometer_feedback = NaN;
                sample_counter = 1; % uses data from 'DOWN', 'UP', 'rest' conditions for collection of samples for feedback-standardization
            elseif contains(experiment{experiment_count,3},'begin_block')
                begin_sampling = current_image_count;
            end
            
            if ~contains(experiment{experiment_count,1},'wait') || ~contains(experiment{experiment_count,1},'instruct')
                
                %% Produce real-time Feedback
                if ~contains(experiment{experiment_count,2},'transfer')
                    if contains(experiment{experiment_count,1},'UP_trial') || contains(experiment{experiment_count,1},'DOWN_trial')
                        
                        %% Calculate feedback value
                        % Method to correct nuisance signal: Subtract control ROI signal from amygdala signal
                        switch FeedbackScaleMethod
                            case 'AdaptiveScale'
                                BrainSignal(1) = detrend_out_kalm_Sample(end,1);
                                BrainSignal(2) = detrend_out_kalm_Sample(end,2);
                                BrainSignal(3) = BrainSignal(1)-BrainSignal(2);
                                raw_feedback = (BrainSignal(3)-local_mean)/(local_SD); % multiply local_SD with factor 0.49, then thermometer range is from -1.96 SD to 1.96 SD aroung the mean
                            case 'GenericScale'
                                BrainSignal(1) = detrend_out_kalm_Sample(end,1)/mean(V(:,1))*100; % percent signal change; PSC
                                BrainSignal(2) = detrend_out_kalm_Sample(end,2)/mean(V(:,2))*100;
                                BrainSignal(3) = BrainSignal(1)-BrainSignal(2);
                                raw_feedback = BrainSignal(3)/0.5; % with a 9-level thermometer (i.e. rangeing from -4 to +4) and one thermometerunit (i.e. bar size) corresponding to 0.5 PSC, we display -2 to +2 PSC
                        end
                        
                        % Produce Feedback for 9-level Thermometer (mean raw-feedback values correspond to median "temperature")
                        thermometer_feedback = round(raw_feedback) + 5;
                        if thermometer_feedback > 9
                            thermometer_feedback = 9;
                        elseif thermometer_feedback < 1
                            thermometer_feedback = 1;
                        end
                        
                        event_list{10} = raw_feedback;
                        event_list{11} = thermometer_feedback;
                        
                    else
                        thermometer_feedback = NaN;
                    end
                end
            end
                                   
            %% Call conditions in Presentation software and send results via tcpip
            if rtconfig.port > 0
                disp(['condition: ' experiment{experiment_count,1}])
                
                try
                    fprintf(tc, '%s ', experiment{experiment_count,1});
                catch
                    fprintf(2, 'error writing condition label to tcp socket\n');
                end

                if contains(experiment{experiment_count,1},'UP_trial') || contains(experiment{experiment_count,1},'DOWN_trial') % in this case Presentation expects further information
                    disp(['feedback: ' int2str(thermometer_feedback)]);
                    try
                        fprintf(tc, '%s ', experiment{experiment_count,2}); % Presentation expects information  of type
                        if contains(experiment{experiment_count,2},'training')
                            fprintf(tc, '%d ', thermometer_feedback); % Presentation expects feedback value in UP/DOWN condition
                        end
                    catch
                        fprintf(2, 'error writing type and feedback to tcp socket\n');
                    end
                end
               
            end
        end
        
        current_image_count = current_image_count + 1;
        
        if ~catch_up || ~present_betaFB
            protocol.table = [protocol.table; experiment(experiment_count,:) event_list];
        else
            protocol.table = [protocol.table; cell(1,3) event_list];
        end
        
    end
   
end