% Copyright 2024 Eelke Spaak, Donders Institute.
% See https://github.com/Spaak/rift-phase-and-visibility for readme/license.
% Belongs with:
% Spaak, E., Bouwkamp, F. G., & de Lange, F. P. (2024). Perceptual foundation and extension
% to phase tagging for rapid invisible frequency tagging (RIFT). Imaging Neuroscience, 2, 1–14.
% https://doi.org/10.1162/imag_a_00242

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