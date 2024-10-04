% Copyright 2024 Eelke Spaak, Donders Institute.
% See https://github.com/Spaak/rift-phase-and-visibility for readme/license.
% Belongs with:
% Spaak, E., Bouwkamp, F. G., & de Lange, F. P. (2024). Perceptual foundation and extension
% to phase tagging for rapid invisible frequency tagging (RIFT). Imaging Neuroscience, 2, 1–14.
% https://doi.org/10.1162/imag_a_00242

function data = fetch_clean_data(subj_id, use_attentional)

if nargin < 2
  use_attentional = false;
end

% load data
if use_attentional
  load(sprintf('/project/3018045.03/scratch/sub%03d-cleaned-600Hz-attnblocks.mat', subj_id),...
  'data_resampled');
else
  load(sprintf('/project/3018045.03/scratch/sub%03d-cleaned-600Hz.mat', subj_id),...
  'data_resampled');
end
data = data_resampled;

load(sprintf('/project/3018045.03/scratch/sub%03d-preproc-ica-demean-weights.mat', subj_id),...
  'unmixing', 'topolabel');

cfg = [];
cfg.method = 'predefined mixing matrix';
cfg.demean = 'no';
cfg.channel = {'MEG'};
cfg.topolabel = topolabel;
cfg.unmixing = unmixing;
comp = ft_componentanalysis(cfg, data);

load(sprintf('/project/3018045.03/scratch/sub%03d-preproc-ica-badcomps.mat', subj_id),...
  'badcomps', 'badcomps_reasons');

cfg = [];
cfg.demean = 'no';
cfg.component = badcomps;
datmeg = ft_rejectcomponent(cfg, comp);

cfg = [];
cfg.channel = {'tag*', 'UADC001'};
datsens = ft_selectdata(cfg, data);

data = ft_appenddata([], datmeg, datsens);
data.grad = datmeg.grad;

end