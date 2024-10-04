%% load experiment log file

subj_id = 14;

load(fetch_filename(subj_id, 'beh'));

%% read in meg (and sensor) data for passive viewing blocks

if subj_id == 1
  use_old_trigs = 1;
else
  use_old_trigs = 0;
end

addpath ../expscript_v3

cfg = [];
cfg.dataset = fetch_filename(subj_id, 'meg');
cfg.trialdef.eventtype = 'UPPT001';

% for some reason event detection on UPPT001 does not work well for sub006,
% even though the events appear perfectly fine in the data browser. Using
% frontpanel trigger as the detection channel resolves this.
if subj_id == 6
  cfg.trialdef.eventtype = 'frontpanel trigger';
end

% MakeOnsetTrig(num_stims, tag_type, random_phases, use_phasetag, is_attn, use_old_version)
% last argument = use_old_version, needed for sub001 and earlier pilots
% when there was a small bug in MakeOnsetTrig (not critical when using
% metadata from exp logfile)

% block spec from exp script
% % attentional blocks
% blk_att = {
%            {'attn', [60 66], 1, 1, 0}; % two freqs, type 1, random phases, no phasetag
%            {'attn', [60 60], 1, 1, 1}; % one freq , type 1, random phases, phasetag
%           };

alltrigs = [
  % attentional trials (require different timing)
   MakeOnsetTrig(2, 1, 1, 0, 1, use_old_trigs)
   MakeOnsetTrig(2, 1, 1, 1, 1, use_old_trigs)
  ];

% timepoint 0 for attentional trials is onset of gratings (just like the
% passive viewing blocks), but pre-zero there was the attentional cue (and
% before the attn cue there was the fixation baseline)

cfg.trialdef.eventvalue = alltrigs;
cfg.trialdef.prestim = 0.9; % 0.4s baseline, 0.5s cue
cfg.trialdef.poststim = 1.2; % 1.2s stims
cfg = ft_definetrial(cfg);

cfg.channel = {'MEG', 'UADC001'};
cfg.continuous = 'yes';
data_raw = ft_preprocessing(cfg);

% add column of trial ID to trialinfo
% start at 751 to identify attentional trials
% first trials 1-750 are passive viewing trials
data_raw.trialinfo = 750 + [(1:numel(data_raw.trial))' data_raw.trialinfo];

%% append corrected tag signals

[data_withtag,meta_columns] = append_corrected_tagsigs_v3_and_metadata_attnblocks(data_raw, stim);

%% summary mode artifact reject

% note: do on data without tagging to avoid issues with nans
cfg = [];
cfg.channel = {'MEG'};
cfg.method = 'summary';
cfg.layout = 'CTF275_helmet.mat';

data_clean = ft_rejectvisual(cfg, data_raw);

%% apply cleaning, downsample, save

badtri = [8, 20, 28, 31, 33, 42, 44, 49, 60, 68, 69, 72, 79, 81, 86, 87, 91, 92, 101, 104, 111, 116, 120, 121, 132, 136, 145, 147, 155, 163, 165, 173, 174, 187, 193, 194, 195, 196];
badchan = {};

cfg = [];
cfg.channel = [{'all'} badchan];
cfg.trials = setdiff(1:numel(data_withtag.trial), badtri);
data_withtag_clean = ft_selectdata(cfg, data_withtag);

cfg = [];
cfg.resamplefs = 600;
cfg.detrend = 'no';
cfg.demean = 'yes';
cfg.baselinewindow = [-0.3 -0.1];
data_resampled = ft_resampledata(cfg, data_withtag_clean);

save(sprintf('/project/3018045.03/scratch/sub%03d-cleaned-600Hz-attnblocks.mat', subj_id),...
  'data_resampled', '-v7.3');

%% check with databrowser

cfg = [];
cfg.viewmode = 'butterfly';
cfg.preproc.demean = 'yes';
cfg.preproc.baselinewindow = [-0.2 0];
cfg.channel = {'UADC001', 'tag1'};
%cfg.mychan = {'UADC001'};
%cfg.mychanscale = 1e2;
%cfg.trials = datsub.trialinfo(:,2) == 2;
ft_databrowser(cfg, data_withtag_clean);

