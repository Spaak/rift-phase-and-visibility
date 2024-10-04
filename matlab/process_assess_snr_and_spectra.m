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
         'numstim', 1, 'tag_type', 2, 'random_phases', 0, 'freq1', 60;
         'numstim', 1, 'tag_type', 3, 'random_phases', 0, 'freq1', 60;
         'numstim', 1, 'tag_type', 4, 'random_phases', 0, 'freq1', 60;
         'numstim', 1, 'tag_type', 1, 'random_phases', 1, 'freq1', 60;
         'numstim', 1, 'tag_type', 4, 'random_phases', 1, 'freq1', 60;
         'numstim', 1, 'tag_type', 1, 'random_phases', 0, 'freq1', 0};

ncond = size(conds, 1);

plotchans = {'MLO11', 'MLO12', 'MLO13', 'MLO14', 'MLO21', 'MLO22', 'MLO23',...
  'MLO24', 'MLO31', 'MLO32', 'MLO34', 'MLO41', 'MLO42', 'MLO43', 'MLO44',...
  'MLO53', 'MLP31', 'MLP41', 'MLP42', 'MLP51', 'MLP52', 'MLP53', 'MLP54',...
  'MLP55', 'MLT16', 'MLT27', 'MLT47', 'MLT57', 'MRO11', 'MRO12', 'MRO13',...
  'MRO14', 'MRO21', 'MRO22', 'MRO23', 'MRO24', 'MRO31', 'MRO32', 'MRO34',...
  'MRO41', 'MRO42', 'MRO43', 'MRO44', 'MRO53', 'MRP31', 'MRP41', 'MRP42',...
  'MRP51', 'MRP52', 'MRP53', 'MRP55', 'MRT16', 'MRT27', 'MRT47', 'MRT57',...
  'MZO01', 'MZO02', 'MZP01'};

% dir for plotting
plotdir = '/home/predatt/eelspa/riftbasics/analysis-4paper/plots';
mkdir(plotdir);

refchan = 'tag1';
foi = 60;

% sub X cond cell arrays
all_freqpow_avg = {};
all_coh = {};
all_snr_pow_tri_db = {};
all_snr_pow_avg_db = {};
all_snr_coh_db = {};

for k = 1:numel(all_subs)
  subj_id = all_subs(k);
  fprintf('loading subject %03d (%d of %d)...\n', subj_id, k, numel(all_subs));
  
  res = load(sprintf('/project/3018045.03/scratch/sub%03d-snr-and-spectra.mat', subj_id));
  all_freqpow_avg(k,:) = res.all_freqpow_avg;
  all_coh(k,:) = res.all_coh;
  all_snr_pow_tri_db(k,:) = res.all_snr_pow_tri_db;
  all_snr_pow_avg_db(k,:) = res.all_snr_pow_avg_db;
  all_snr_coh_db(k,:) = res.all_snr_coh_db;
end

% convert non-trial-resolved data to normal arrays
all_snr_coh_db = cell2mat(all_snr_coh_db);
all_snr_pow_avg_db = cell2mat(all_snr_pow_avg_db);

%% plot topos

% 7x2 plot, columns are conditions, top = pow, bottom = coh

foi = 60;

allga_pow = {};
for cond = 1:ncond
  allga_pow{cond} = ft_freqgrandaverage([], all_freqpow_avg{:,cond});
  
  % express coherence spectrum as "power"-spectrum to facilitate averaging
  tmp = {};
  for k = 1:nsub
    tmp{k} = all_freqpow_avg{k,cond};
    tmp{k}.powspctrm = all_coh{k,cond}.cohspctrm;
  end
  allga_coh{cond} = ft_freqgrandaverage([], tmp{:});
end

% determine limits
assert(allga_pow{1}.freq(60) == foi);
assert(allga_coh{1}.freq(60) == foi);
allcoh = cellfun(@(x) x.powspctrm(:,60), allga_coh, 'uniformoutput', false);
cohlim = max(cat(1, allcoh{:}));
allpow = cellfun(@(x) x.powspctrm(:,60), allga_pow, 'uniformoutput', false);
powlim = max(cat(1, allpow{:}));

set(0, 'defaultAxesFontSize',20)
f = figure('windowstate', 'maximized', 'color', 'w');
for cond = 1:ncond
  chaninds = match_str(allga_pow{cond}.label, plotchans);
  
  subtightplot(2,7,cond);
  
  cfg = [];
  cfg.figure = 'gca';
  cfg.interactive = 'no';
  cfg.layout = 'CTF275_helmet.mat';
  cfg.highlight = 'on';
  cfg.highlightchannel = plotchans;
  cfg.highlightsymbol = '.';
  cfg.style = 'straight';
  cfg.marker = 'off';
  cfg.comment = 'no';
  cfg.colorbar = 'no';
  cfg.xlim = [foi foi];
  cfg.zlim = [0 powlim];
  cfg.gridscale = 100;
  ft_topoplotER(cfg, allga_pow{cond});
  
  subtightplot(2,7,7+cond);
  
  cfg.zlim = [0 cohlim];
  ft_topoplotER(cfg, allga_coh{cond});
  
end

f2 = figure('color', 'w');
colorbar();

exportgraphics(f, sprintf('%s/topos-tagtypes-fixedphases.pdf', plotdir),...
    'Resolution', 150, 'contenttype', 'vector');
exportgraphics(f2, sprintf('%s/colorbar.pdf', plotdir),...
    'Resolution', 150, 'contenttype', 'vector');


%% export for analysis and plotting in Python

% average over channels
% sub X cond X freq

allspec_pow = nan(nsub, ncond, 100);
allspec_coh = nan(nsub, ncond, 100);
for k = 1:nsub
  for cond = 1:ncond
    assert(isequal(all_freqpow_avg{k,cond}.label, all_coh{k,cond}.labelcmb(:,1)));
    chaninds = match_str(all_freqpow_avg{k,cond}.label, plotchans);
    allspec_pow(k,cond,:) = squeeze(mean(all_freqpow_avg{k,cond}.powspctrm(chaninds,:), 1));
    allspec_coh(k,cond,:) = squeeze(mean(all_coh{k,cond}.cohspctrm(chaninds,:), 1));
  end
end

% long-form csv export
headers = {'frequency', 'subject', 'condition', 'coherence', 'power'};
alldat = [];

for k = 1:nsub
  for cond = 1:ncond
    thisdat = [(1:100)' ones(100,1)*k ones(100,1)*cond squeeze(allspec_coh(k,cond,:)) squeeze(allspec_pow(k,cond,:))];
    alldat = [alldat; thisdat];
  end
end

T = array2table(alldat, 'VariableNames', headers');
writetable(T, '/project/3018045.03/scratch/aggr-singlestim-spectra.csv');


% trial-averaged data for snr
headers = {'subject', 'condition', 'snr_coherence', 'snr_power_avg'};
alldat = [];
for k = 1:nsub
  for cond = 1:ncond
    thisdat = [k cond all_snr_coh_db(k,cond) all_snr_pow_avg_db(k,cond)];
    alldat = [alldat; thisdat];
  end
end
T = array2table(alldat, 'VariableNames', headers');
writetable(T, '/project/3018045.03/scratch/aggr-singlestim-snr-triavg.csv');


%% check number of channels for participants (for reporting in methods section)

nchan = zeros(nsub, 1);
for k = 1:nsub
    nchan(k) = size(all_freqpow_avg{k,1}.powspctrm, 1);
end