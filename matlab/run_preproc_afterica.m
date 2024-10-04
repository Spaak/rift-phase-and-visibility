% Copyright 2024 Eelke Spaak, Donders Institute.
% See https://github.com/Spaak/rift-phase-and-visibility for readme/license.
% Belongs with:
% Spaak, E., Bouwkamp, F. G., & de Lange, F. P. (2024). Perceptual foundation and extension
% to phase tagging for rapid invisible frequency tagging (RIFT). Imaging Neuroscience, 2, 1–14.
% https://doi.org/10.1162/imag_a_00242

%% load data and projection

subj_id = 6;

load(sprintf('/project/3018045.03/scratch/sub%03d-cleaned-600Hz.mat', subj_id),...
  'data_resampled');
load(sprintf('/project/3018045.03/scratch/sub%03d-preproc-ica-demean-weights.mat', subj_id),...
  'unmixing', 'topolabel');

%%

cfg = [];
cfg.method = 'predefined mixing matrix';
cfg.demean = 'no';
cfg.channel = {'MEG'};
cfg.topolabel = topolabel;
cfg.unmixing = unmixing;
comp = ft_componentanalysis(cfg, data_resampled);

%%

cfg = [];
cfg.viewmode = 'component';
cfg.layout = 'CTF275_helmet.mat';
cfg.zlim = 'maxabs';
cfg.compscale = 'local';
ft_databrowser(cfg, comp);


%% write down and save

badcomps = [3 8];
badcomps_reasons = {'ecg', 'ecg'};

assert(numel(badcomps) == numel(badcomps_reasons));

save(sprintf('/project/3018045.03/scratch/sub%03d-preproc-ica-badcomps.mat', subj_id),...
  'badcomps', 'badcomps_reasons');

% %% diagnose: are there really such weird weights?
% no, see: https://github.com/fieldtrip/fieldtrip/issues/1702
% 
% tl = [];
% tl.label = comp.topolabel;
% tl.time = 0;
% tl.avg = comp.topo(:,2);
% tl.dimord = 'chan_time';
% 
% cfg = [];
% cfg.layout = 'CTF275_helmet.mat';
% cfg.zlim = 'maxabs';
% cfg.colorbar = 'yes';
% ft_topoplotER(cfg, tl);
% 
% %% check comp browser with data from disk
% 
% close all;
% clear all;
% clear ft_databrowser;
% 
% load /home/common/matlab/fieldtrip/data/test/latest/comp/meg/comp_ctf275.mat
% 
% cfg = [];
% cfg.viewmode = 'component';
% cfg.layout = 'CTF275_helmet.mat';
% cfg.zlim = 'maxabs';
% cfg.compscale = 'local';
% ft_databrowser(cfg, comp);