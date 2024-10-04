function job_phaseproject_dipolefit(subj_id)

fprintf('subj_id = %d\n', subj_id);

% load data
data = fetch_clean_data(subj_id);

conds = {'numstim', 1, 'tag_type', 1, 'random_phases', 0, 'freq1', 60;
         'numstim', 1, 'tag_type', 2, 'random_phases', 0, 'freq1', 60;
         'numstim', 1, 'tag_type', 3, 'random_phases', 0, 'freq1', 60;
         'numstim', 1, 'tag_type', 4, 'random_phases', 0, 'freq1', 60;
         'numstim', 1, 'tag_type', 1, 'random_phases', 1, 'freq1', 60;
         'numstim', 1, 'tag_type', 4, 'random_phases', 1, 'freq1', 60;
         'numstim', 1, 'tag_type', 1, 'random_phases', 0, 'freq1', 0};

ncond = size(conds, 1);

cfg = [];
cfg.latency = [0.2 1.2];

% only single tagging type (1/4) at a time
trials = make_trial_selection(data, 'numstim', 1, 'tag_type', 4, 'random_phases', 1, 'freq1', 60);
cfg.trials = trials;
data_onestim = ft_selectdata(cfg, data);

trials = make_trial_selection(data, 'numstim', 2, 'tag_type', 4, 'random_phases', 1, 'use_phasetag', 1, 'freq1', 60, 'freq2', 60);
cfg.trials = trials;
data_twostim = ft_selectdata(cfg, data);

% dir for plotting
plotdir = '/project/3018045.03/plots/2023-03-16-phaseproject-topos-dipolefits-tagtype4';
mkdir(plotdir);

%% fft

refchan = 'tag1';

cfg = [];
cfg.method = 'mtmfft';
cfg.taper = 'boxcar';
cfg.output = 'fourier';
cfg.keeptrials = 'yes';
cfg.channel = {'MEG', refchan};
cfg.foilim = [1 100];
freq_onestim = ft_freqanalysis(cfg, data_onestim);
freq_twostim = ft_freqanalysis(cfg, data_twostim);

%% pipeline: figure out peak phase for one stim trials, project two-stim, get topos for 0 and 90 deg

refchanind = match_str(freq_onestim.label, 'tag1');

% use the following phases
% this can probably be optimized a lot (likely no need to brute force
% iterate over phase bins), but for now this should do the job and make it
% easy to understand
ph_coh = 0:pi/16:2*pi-pi/16; % 32 phase bins
nchan = numel(freq_onestim.label)-1;

% used to store phase X channel activity profiles
act_coh_onestim = nan(numel(ph_coh), nchan);
act_coh_twostim = nan(numel(ph_coh), nchan);

% fourier coefficients corrected for tagging phase
% trial X channel
four_onestim = freq_onestim.fourierspctrm(:,1:end-1,60) ./ freq_onestim.fourierspctrm(:,refchanind,60);
four_twostim = freq_twostim.fourierspctrm(:,1:end-1,60) ./ freq_twostim.fourierspctrm(:,refchanind,60);

for k = 1:numel(ph_coh)
  ph = ph_coh(k);
  
  % unit phase factor into which to project
  phfac = exp(1j*ph);
  % feats = [real(freq.crsspctrm) imag(freq.crsspctrm)] * [real(phfac); imag(phfac)];
  % the dot product only works when freq.crsspctrm is 1d, the below works with 2d
  % (rpt_chan)
  tmp = permute(cat(3, real(four_onestim), imag(four_onestim)), [1 3 2]);
  % tmp is now rpt_chan_ReIm
  feats = squeeze(pagemtimes(tmp, [real(phfac); imag(phfac)]));
  % feats is now rpt_chan

  % overall strength of projection along ph, averaged across trials
  act_coh_onestim(k,:) = mean(feats, 1);

  tmp = permute(cat(3, real(four_twostim), imag(four_twostim)), [1 3 2]);
  feats = squeeze(pagemtimes(tmp, [real(phfac); imag(phfac)]));
  act_coh_twostim(k,:) = mean(feats, 1);
end

% figure out peak phase by taking max-variance (or max-range?)
topovar = var(act_coh_onestim, [], 2);
[~,peakph_ind] = max(topovar);
peakph = ph_coh(peakph_ind);

%assert(peakph < pi); % max should return the first peak, but we expect another one of equal height >= pi
% assertion sometimes fails for some rounding issues, simply take mod(pi)
% instead
peakph = mod(peakph, pi);

% plot topos of the two stim case at the selected lag and at 90 deg shift
clim = max(act_coh_twostim(:));

tmp = [];
tmp.label = freq_onestim.label(1:end-1);
tmp.dimord = 'chan_time';
tmp.time = 1;

cfg = [];
cfg.figure = 'gca';
cfg.interactive = 'no';
cfg.layout = 'CTF275_helmet.mat';
cfg.style = 'straight';
cfg.marker = 'off';
cfg.comment = 'no';
cfg.colorbar = 'no';
cfg.zlim = [-clim clim];

f = figure('defaultaxesfontsize', 12);

subplot(1,2,1);
tmp.avg = act_coh_twostim(peakph_ind,:)';
ft_topoplotER(cfg, tmp);
title(sprintf('two stims, phase = %.3g (peak for one-stim trials)', peakph));

shiftedph = mod(peakph + pi/2, 2*pi);
[~,shiftedph_ind] = min(abs(ph_coh-shiftedph));

subplot(1,2,2);
tmp.avg = act_coh_twostim(shiftedph_ind,:)';
ft_topoplotER(cfg, tmp);
title(sprintf('two stims, phase = %.3g (90deg shift)', shiftedph));

exportgraphics(f, sprintf('%s/topos-s%03d.pdf', plotdir, subj_id), 'Resolution', 150);
close(f);


%% dipole fits to the above 0 and 90 deg shifted topos of coherency

% see run_interactive_template_warp_headmodel for how to get MEG volume
% conduction model based on individual headshape info and template anatomy

hdm = load(sprintf('/project/3018045.03/scratch/sub%03d-headmodel-template-warped.mat', subj_id));
headmodel = hdm.headmodel_singleshell;
transform_template2polhemus = hdm.transform_template2polhemus;

% utility functions to transform geometry
mni2ctf = @(pos) ft_warp_apply(transform_template2polhemus, pos);
ctf2mni = @(pos) ft_warp_apply(pinv(transform_template2polhemus), pos);

assert(isequal(freq_onestim.label, freq_twostim.label));

% wrap in FT TL structure
tl_peak = [];
tl_peak.label = freq_onestim.label(1:end-1);
tl_peak.dimord = 'chan_time';
tl_peak.time = 1;
tl_peak.avg = act_coh_twostim(peakph_ind,:)';
tl_peak.grad = ft_convert_units(freq_onestim.grad, 'mm');
tl_shift = tl_peak;
tl_shift.avg = act_coh_twostim(shiftedph_ind,:)';

cfg = [];
cfg.numdipoles = 1;
cfg.headmodel = headmodel;
cfg.gridsearch = 'no';
cfg.dip.pos = mni2ctf([0 -88 -9]); % calcarine sulcus, central
dip_peak = ft_dipolefitting(cfg, tl_peak);
dip_shift = ft_dipolefitting(cfg, tl_shift);

% some feedback
r_peak = corr(dip_peak.Vdata, dip_peak.Vmodel);
r_shift = corr(dip_shift.Vdata, dip_shift.Vmodel);
fprintf('for coherency at peak phase, explained var = %.3g\n', r_peak.^2);
fprintf('for coherency at shifted phase, explained var = %.3g\n', r_shift.^2);

pos_peak_mni = ctf2mni(dip_peak.dip.pos);
pos_shift_mni = ctf2mni(dip_shift.dip.pos);

%% coherence on single trials for two-stim case, peak/shift phase

% uses refchanind, peakph, and shiftedph defined above

ntri = size(freq_twostim.fourierspctrm, 1);

% fourier coefficients corrected for tagging phase
% trial X channel
four_twostim = freq_twostim.fourierspctrm(:,1:end-1,60) ./ freq_twostim.fourierspctrm(:,refchanind,60);

phfac = exp(1j*peakph);
% feats = [real(freq.crsspctrm) imag(freq.crsspctrm)] * [real(phfac); imag(phfac)];
% the dot product only works when freq.crsspctrm is 1d, the below works with 2d
% (rpt_chan)
tmp = permute(cat(3, real(four_twostim), imag(four_twostim)), [1 3 2]);
act_peakphase = squeeze(pagemtimes(tmp, [real(phfac); imag(phfac)]));

phfac = exp(1j*shiftedph);
tmp = permute(cat(3, real(four_twostim), imag(four_twostim)), [1 3 2]);
act_shiftedphase = squeeze(pagemtimes(tmp, [real(phfac); imag(phfac)]));

% act_peakphase and act_shiftphase are now trial X channel activity profiles

%% dipole fits per trial (takes about 2min for both phases, 67 trials)

cfg = [];
cfg.numdipoles = 1;
cfg.headmodel = headmodel;
cfg.gridsearch = 'no';
cfg.dip.pos = mni2ctf([0 -88 -9]); % calcarine sulcus, central
cfg.model = 'moving'; % moving across "time" but actually it's the trial dimension

tl = [];
tl.label = freq_onestim.label(1:end-1);
tl.dimord = 'chan_time';
tl.time = 1:ntri;
tl.avg = act_peakphase';
tl.grad = ft_convert_units(freq_onestim.grad, 'mm');

tri_dip_peak = ft_dipolefitting(cfg, tl);

tl.avg = act_shiftedphase';
tri_dip_shift = ft_dipolefitting(cfg, tl);

tripos_peak = ctf2mni(cat(1, tri_dip_peak.dip.pos));
tripos_shift = ctf2mni(cat(1, tri_dip_shift.dip.pos));

trir2_peak = diag(corr(tri_dip_peak.Vdata, tri_dip_peak.Vmodel)).^2;
trir2_shift = diag(corr(tri_dip_shift.Vdata, tri_dip_shift.Vmodel)).^2;

%% save

save(sprintf('/project/3018045.03/scratch/sub%03d-phaseproject-topos-dipfits-alltri-tagtype4.mat', subj_id),...
  'pos_peak_mni', 'pos_shift_mni', 'dip_peak', 'dip_shift', 'tl_peak',...
  'tl_shift', 'peakph', 'shiftedph', 'tri_dip_peak', 'tri_dip_shift',...
  'tripos_peak', 'tripos_shift', 'trir2_peak', 'trir2_shift');


end