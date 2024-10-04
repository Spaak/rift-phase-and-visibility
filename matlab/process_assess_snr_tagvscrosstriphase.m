% Copyright 2024 Eelke Spaak, Donders Institute.
% See https://github.com/Spaak/rift-phase-and-visibility for readme/license.
% Belongs with:
% Spaak, E., Bouwkamp, F. G., & de Lange, F. P. (2024). Perceptual foundation and extension
% to phase tagging for rapid invisible frequency tagging (RIFT). Imaging Neuroscience, 2, 1–14.
% https://doi.org/10.1162/imag_a_00242

%% load results

all_subs = [1 3 4 5 6 7 8 9 10 11 13 14];
nsub = numel(all_subs);

% mainly for reference
conds = {'numstim', 1, 'tag_type', 1, 'random_phases', 0, 'freq1', 60;
         'numstim', 1, 'tag_type', 4, 'random_phases', 0, 'freq1', 60;
         'numstim', 1, 'tag_type', 1, 'random_phases', 1, 'freq1', 60;
         'numstim', 1, 'tag_type', 4, 'random_phases', 1, 'freq1', 60};

ncond = size(conds, 1);

plotchans = {'MLO11', 'MLO12', 'MLO13', 'MLO14', 'MLO21', 'MLO22', 'MLO23',...
  'MLO24', 'MLO31', 'MLO32', 'MLO34', 'MLO41', 'MLO42', 'MLO43', 'MLO44',...
  'MLO53', 'MLP31', 'MLP41', 'MLP42', 'MLP51', 'MLP52', 'MLP53', 'MLP54',...
  'MLP55', 'MLT16', 'MLT27', 'MLT47', 'MLT57', 'MRO11', 'MRO12', 'MRO13',...
  'MRO14', 'MRO21', 'MRO22', 'MRO23', 'MRO24', 'MRO31', 'MRO32', 'MRO34',...
  'MRO41', 'MRO42', 'MRO43', 'MRO44', 'MRO53', 'MRP31', 'MRP41', 'MRP42',...
  'MRP51', 'MRP52', 'MRP53', 'MRP55', 'MRT16', 'MRT27', 'MRT47', 'MRT57',...
  'MZO01', 'MZO02', 'MZP01'};


refchan = 'tag1';
foi = 60;

% sub X cond cell arrays
all_snr_coh_db = {};
all_snr_itc_db = {};

for k = 1:numel(all_subs)
  subj_id = all_subs(k);
  fprintf('loading subject %03d (%d of %d)...\n', subj_id, k, numel(all_subs));
  
  res = load(sprintf('/project/3018045.03/scratch/sub%03d-snr-tagvscrosstriphase.mat', subj_id));
  all_snr_coh_db(k,:) = res.all_snr_coh_db;
  all_snr_itc_db(k,:) = res.all_snr_itc_db;
end

% convert non-trial-resolved data to normal arrays
all_snr_coh_db = cell2mat(all_snr_coh_db);
all_snr_itc_db = cell2mat(all_snr_itc_db);

%% export for analysis in Python

headers = {'Subject', 'Tagging', 'PhasesRandom', 'SNR', 'Corrected'};
alldat = [];
for k = 1:nsub
  for cond = 1:ncond
      if cond==1 || cond==3
          tagging = 1;
      else
          tagging = 4;
      end
      if cond==1 || cond==2
          phases_random = 0;
      else
          phases_random = 1;
      end
    thisdat1 = [k tagging phases_random all_snr_coh_db(k,cond) 1];
    thisdat2 = [k tagging phases_random all_snr_itc_db(k,cond) 0];
    alldat = [alldat; thisdat1; thisdat2];
  end
end
T = array2table(alldat, 'VariableNames', headers');
writetable(T, '/project/3018045.03/scratch/aggr-singlestim-snr-tagvscrosstriphase.csv');
