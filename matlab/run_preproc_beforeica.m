% Copyright 2024 Eelke Spaak, Donders Institute.
% See https://github.com/Spaak/rift-phase-and-visibility for readme/license.
% Belongs with:
% Spaak, E., Bouwkamp, F. G., & de Lange, F. P. (2024). Perceptual foundation and extension
% to phase tagging for rapid invisible frequency tagging (RIFT). Imaging Neuroscience, 2, 1–14.
% https://doi.org/10.1162/imag_a_00242

%% load experiment log file

subj_id = 6;

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
% blk_pas = {% single stim, four tagging types, fixed phases
%            {'single', 60, 1, 0};
%            {'single', 60, 2, 0};
%            {'single', 60, 3, 0};
%            {'single', 60, 4, 0};
%            % single stim, tagging type 1 and 4, random phases
%            {'single', 60, 1, 1};
%            {'single', 60, 4, 1};
%            % two stims with tagging
%            {'double', [60 66], 1, 1, 0}; % two freqs, type 1, random phases, no phasetag
%            {'double', [60 60], 1, 1, 1}; % one freq , type 1, random phases, phasetag
%            {'double', [60 66], 4, 1, 0}; % two freqs, type 4, random phases, no phasetag
%            {'double', [60 60], 4, 1, 1}; % one freq , type 4, random phases, phasetag
%            % stims without tagging ("type 1" for black background)
%            {'single', 0, 1, 0};
%            {'double', [0 0], 1, 0, 0}
%           };
% % attentional blocks
% blk_att = {
%            {'attn', [60 66], 1, 1, 0}; % two freqs, type 1, random phases, no phasetag
%            {'attn', [60 60], 1, 1, 1}; % one freq , type 1, random phases, phasetag
%           };

alltrigs = [
  MakeOnsetTrig(1, 1, 0, 0, 0, use_old_trigs)
  MakeOnsetTrig(1, 2, 0, 0, 0, use_old_trigs)
  MakeOnsetTrig(1, 3, 0, 0, 0, use_old_trigs)
  MakeOnsetTrig(1, 4, 0, 0, 0, use_old_trigs)
  
  MakeOnsetTrig(1, 1, 1, 0, 0, use_old_trigs)
  MakeOnsetTrig(1, 4, 1, 0, 0, use_old_trigs)
  
  MakeOnsetTrig(2, 1, 1, 0, 0, use_old_trigs)
  MakeOnsetTrig(2, 1, 1, 1, 0, use_old_trigs)
  MakeOnsetTrig(2, 4, 1, 0, 0, use_old_trigs)
  MakeOnsetTrig(2, 4, 1, 1, 0, use_old_trigs)
  
  MakeOnsetTrig(1, 1, 0, 0, 0, use_old_trigs) % redundant but add for completeness
  MakeOnsetTrig(2, 1, 0, 0, 0, use_old_trigs) % redundant but add for completeness
  
  % attentional trials (require different timing so read in later)
%   MakeOnsetTrig(2, 1, 1, 0, 1, 1)
%   MakeOnsetTrig(2, 1, 1, 1, 1, 1)
  ];

cfg.trialdef.eventvalue = alltrigs;
cfg.trialdef.prestim = 0.4;
cfg.trialdef.poststim = 1.2;
cfg = ft_definetrial(cfg);

if subj_id == 6
  % first 15 trials are missing for sub006, handle this by replicating the
  % first recorded trial 15 times and removing them later on. This makes
  % the handling of the metadata etc. easier in the next step.
  cfg.trl = cat(1, repmat(cfg.trl(1,:), [15 1]), cfg.trl);
end

cfg.channel = {'MEG', 'UADC001'};
cfg.continuous = 'yes';
data_raw = ft_preprocessing(cfg);

% add column of trial ID to trialinfo
data_raw.trialinfo = [(1:numel(data_raw.trial))' data_raw.trialinfo];

%% append corrected tag signals

[data_withtag,meta_columns] = append_corrected_tagsigs_v3_and_metadata(data_raw, stim);

%% summary mode artifact reject

% note: do on data without tagging to avoid issues with nans
cfg = [];
cfg.channel = {'MEG'};
cfg.method = 'summary';
cfg.layout = 'CTF275_helmet.mat';

if subj_id == 6
  cfg.trials = 16:750;
end

data_clean = ft_rejectvisual(cfg, data_raw);

%% apply cleaning, downsample, save

badtri = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 20, 35, 39, 45, 46, 48, 49, 50, 51, 52, 53, 54, 67, 79, 81, 88, 89, 100, 105, 108, 110, 111, 119, 123, 124, 127, 129, 134, 135, 136, 142, 145, 146, 147, 158, 161, 167, 170, 178, 181, 198, 207, 210, 226, 230, 252, 253, 275, 276, 287, 298, 301, 310, 314, 323, 335, 343, 356, 365, 366, 373, 378, 388, 396, 397, 414, 420, 421, 435, 447, 448, 452, 456, 463, 481, 482, 483, 488, 492, 493, 498, 512, 519, 524, 525, 551, 552, 555, 556, 572, 573, 574, 575, 587, 597, 603, 610, 617, 630, 636, 647, 653, 670, 673, 676, 680, 691, 705, 706, 716, 726, 727, 732, 750];
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

save(sprintf('/project/3018045.03/scratch/sub%03d-cleaned-600Hz.mat', subj_id),...
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

