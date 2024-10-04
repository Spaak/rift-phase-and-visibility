function job_assess_snr_tagvscrosstriphase(subj_id)

fprintf('subj_id = %d\n', subj_id);

% load data
data = fetch_clean_data(subj_id);

% select stim window
cfg = [];
cfg.latency = [0.2 1.2];
data = ft_selectdata(cfg, data);

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

all_freqpow_avg = {};
all_coh = {};
all_snr_pow_tri_db = {};
all_snr_pow_avg_db = {};
all_snr_coh_db = {};

for cond_ind = 1:ncond

  trials = make_trial_selection(data, conds{cond_ind,:});
  assert(sum(trials) <= 50);
  
  cfg = [];
  cfg.trials = trials;
  datcond = ft_selectdata(cfg, data);
  
  cfg = [];
  cfg.method = 'mtmfft';
  cfg.taper = 'boxcar';
  cfg.keeptrials = 'yes';
  cfg.channel = {'MEG' refchan};
  cfg.foilim = [1 100];
  cfg.output = 'fourier';
  freqfourier = ft_freqanalysis(cfg, datcond);
  
  % coherence with (corrected) reference (tagging) channel
  cfg = [];
  cfg.method = 'coh';
  nchan = numel(freqfourier.label)-1;
  cfg.channelcmb = [freqfourier.label(1:end-1) repmat({refchan}, nchan, 1)];
  coh = ft_connectivityanalysis(cfg, freqfourier);
  
  % inter-trial coherence
  cfg = [];
  cfg.channel = 'MEG';
  freqfourier_megonly = ft_selectdata(cfg, freqfourier);
  fourspc = freqfourier_megonly.fourierspctrm;
  fourspc = fourspc ./ abs(fourspc); % set Fourier coeffs to length 1
  itc = squeeze(abs(mean(fourspc, 1))); % abs value of mean normalized Fourier coeffs across trials

  % compute snr by comparing foi to neighbours, both single trials and averaged
  neighbfois = [(foi-5:foi-2) (foi+2:foi+5)];
  
  % snr from coherence
  chaninds = match_str(coh.labelcmb(:,1), plotchans);
  assert(isequal(coh.freq, 1:100));

  noisepow = mean(coh.cohspctrm(:,neighbfois), 2);
  snr = coh.cohspctrm(:,foi) ./ noisepow;
  snr_coh_db = 10 .* log10(mean(snr(chaninds)));
  
  % snr from itc
  chaninds = match_str(freqfourier_megonly.label, plotchans);
  assert(isequal(freqfourier_megonly.freq, 1:100));
  
  noiseitc = mean(itc(:,neighbfois), 2);
  snr = itc(:,foi) ./ noiseitc;
  snr_itc_db = 10 .* log10(mean(snr(chaninds)));
  
  
  % store results (and remove big fields)
  all_snr_coh_db{cond_ind} = snr_coh_db;
  all_snr_itc_db{cond_ind} = snr_itc_db;

end

% save to disk
save(sprintf('/project/3018045.03/scratch/sub%03d-snr-tagvscrosstriphase.mat', subj_id),...
  'all_snr_coh_db', 'all_snr_itc_db');

end