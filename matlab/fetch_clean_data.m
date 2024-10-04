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