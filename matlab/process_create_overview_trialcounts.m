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
