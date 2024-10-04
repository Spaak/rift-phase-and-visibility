% Copyright 2024 Eelke Spaak, Donders Institute.
% See https://github.com/Spaak/rift-phase-and-visibility for readme/license.
% Belongs with:
% Spaak, E., Bouwkamp, F. G., & de Lange, F. P. (2024). Perceptual foundation and extension
% to phase tagging for rapid invisible frequency tagging (RIFT). Imaging Neuroscience, 2, 1–14.
% https://doi.org/10.1162/imag_a_00242

%% load all subjects' data and store trial counts

all_subs = [1 3 4 5 6 7 8 9 10 11 13 14];
nsub = numel(all_subs);

tri_counts = nan(nsub, 1);

for k = 1:nsub
  subj_id = all_subs(k);
  fprintf('loading for subject %d...\n', subj_id);
  load(sprintf('/project/3018045.03/scratch/sub%03d-cleaned-600Hz.mat', subj_id),...
    'data_resampled');
  tri_counts(k) = size(data_resampled.trialinfo, 1);
  clear data_resampled;
end
  
%%

tri_counts_removed = 750 - tri_counts;
