function job_assess_snr_and_spectra(subj_id)

fprintf('subj_id = %d\n', subj_id);

% load data
data = fetch_clean_data(subj_id);

% select stim window
cfg = [];
cfg.latency = [0.2 1.2];
data = ft_selectdata(cfg, data);

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
  cfg.output = 'pow';
  cfg.keeptrials = 'yes';
  cfg.channel = 'MEG';
  cfg.foilim = [1 100];
  freqpow = ft_freqanalysis(cfg, datcond);
  
  cfg.keeptrials = 'no';
  freqpow_avg = ft_freqanalysis(cfg, datcond);
  
  cfg.keeptrials = 'yes';
  cfg.channel = {'MEG' refchan};
  cfg.output = 'fourier';
  freqfourier = ft_freqanalysis(cfg, datcond);
  
  cfg = [];
  cfg.method = 'coh';
  nchan = numel(freqfourier.label)-1;
  cfg.channelcmb = [freqfourier.label(1:end-1) repmat({refchan}, nchan, 1)];
  coh = ft_connectivityanalysis(cfg, freqfourier);


  % compute snr by comparing foi to neighbours, both single trials and averaged
  neighbfois = [(foi-5:foi-2) (foi+2:foi+5)];
  
  chaninds = match_str(freqpow.label, plotchans);

  assert(isequal(freqpow.freq, 1:100));
  noisepow = mean(freqpow.powspctrm(:,:,neighbfois), 3);
  snr = freqpow.powspctrm(:,:,foi) ./ noisepow;
  snr_pow_tri_db = 10 .* log10(mean(snr(:,chaninds), 2));

  meanpow = squeeze(mean(freqpow.powspctrm, 1));
  noisepow = mean(meanpow(:,neighbfois), 2);
  snr = meanpow(:,foi) ./ noisepow;
  snr_pow_avg_db = 10 .* log10(mean(snr(chaninds)));
  

  % snr from coherence
  chaninds = match_str(coh.labelcmb(:,1), plotchans);
  assert(isequal(coh.freq, 1:100));

  noisepow = mean(coh.cohspctrm(:,neighbfois), 2);
  snr = coh.cohspctrm(:,foi) ./ noisepow;
  snr_coh_db = 10 .* log10(mean(snr(chaninds)));
  
  
  % store results (and remove big fields)
  all_freqpow_avg{cond_ind} = rmfield(freqpow_avg, {'cfg', 'grad'});
  all_coh{cond_ind} = rmfield(coh, {'cfg', 'grad'});
  all_snr_pow_tri_db{cond_ind} = snr_pow_tri_db;
  all_snr_pow_avg_db{cond_ind} = snr_pow_avg_db;
  all_snr_coh_db{cond_ind} = snr_coh_db;

end

% save to disk
save(sprintf('/project/3018045.03/scratch/sub%03d-snr-and-spectra.mat', subj_id),...
  'all_freqpow_avg', 'all_coh', 'all_snr_pow_tri_db', 'all_snr_pow_avg_db',...
  'all_snr_coh_db');

end