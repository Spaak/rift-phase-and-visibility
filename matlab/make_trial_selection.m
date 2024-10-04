% Copyright 2024 Eelke Spaak, Donders Institute.
% See https://github.com/Spaak/rift-phase-and-visibility for readme/license.
% Belongs with:
% Spaak, E., Bouwkamp, F. G., & de Lange, F. P. (2024). Perceptual foundation and extension
% to phase tagging for rapid invisible frequency tagging (RIFT). Imaging Neuroscience, 2, 1–14.
% https://doi.org/10.1162/imag_a_00242

function inds = make_trial_selection(data, varargin)

% this applies to sub001 and later
% see seldat.m for earlier pilot003

meta_columns = {'id', 'trig', 'numstim', 'tag_type', 'random_phases',...
    'use_phasetag', 'is_attn', 'freq1', 'freq2', 'phase1', 'phase2',...
    'stimrot1', 'stimrot2', 'attside', 'att_dim_tim', 'respside', 'rt'};

inds = true(size(data.trialinfo, 1), 1);

for k = 1:numel(meta_columns)
  arg = ft_getopt(varargin, meta_columns{k});
  if ~isempty(arg)
    if isnan(arg)
      % handle selection for nans differently
      % needed because we check for non-dimming attentional trials with
      % make_trial_selection(data, ..., 'att_dim_tim', nan)
      inds = inds & isnan(data.trialinfo(:,k));
    else
      inds = inds & data.trialinfo(:,k) == arg;
    end
  end
end

end