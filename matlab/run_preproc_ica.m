function run_preproc_ica(subj_id)

% load data
load(sprintf('/project/3018045.03/scratch/sub%03d-cleaned-600Hz.mat', subj_id),...
  'data_resampled');

cfg = [];
cfg.method = 'runica';
cfg.demean = 'yes';
cfg.channel = {'MEG'}; % only do ICA on MEG channels, not the refchans

comp = ft_componentanalysis(cfg, data_resampled);

unmixing = comp.unmixing;
topolabel = comp.topolabel;

save(sprintf('/project/3018045.03/scratch/sub%03d-preproc-ica-demean-weights.mat', subj_id),...
  'unmixing', 'topolabel');

end