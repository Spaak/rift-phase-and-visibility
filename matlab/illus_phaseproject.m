subj_id = 7;
tag_type = 1;

fprintf('subj_id = %d\n', subj_id);

% load data
data = fetch_clean_data(subj_id);

cfg = [];
cfg.latency = [0.2 1.2];

trials = make_trial_selection(data, 'numstim', 1, 'tag_type', tag_type, 'random_phases', 1, 'freq1', 60);
cfg.trials = trials;
data_onestim = ft_selectdata(cfg, data);

trials = make_trial_selection(data, 'numstim', 2, 'tag_type', tag_type, 'random_phases', 1, 'use_phasetag', 1, 'freq1', 60, 'freq2', 60);
cfg.trials = trials;
data_twostim = ft_selectdata(cfg, data);

% dir for plotting
plotdir = '/home/predatt/eelspa/riftbasics/analysis-4paper/plots';
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

%% pipeline: figure out phase for one stim trials that results in peak var across channels

refchanind = match_str(freq_onestim.label, 'tag1');

% use the following phases
% this can probably be optimized a lot (likely no need to brute force
% iterate over phase bins), but for now this should do the job and make it
% easy to understand
ph_coh = 0:pi/16:2*pi-pi/16; % 32 phase bins
nchan = numel(freq_onestim.label)-1;

% used to store phase X channel activity profiles
act_coh_onestim = nan(numel(ph_coh), nchan);

% fourier coefficients corrected for tagging phase
% trial X channel
assert(freq_onestim.freq(60) == 60);
assert(freq_twostim.freq(60) == 60);
four_onestim = freq_onestim.fourierspctrm(:,1:end-1,60) ./ freq_onestim.fourierspctrm(:,refchanind,60);

for k = 1:numel(ph_coh)
  ph = ph_coh(k);
  
  % unit phase factor into which to project
  phfac = exp(1j*ph);
  % feats = [real(freq.crsspctrm) imag(freq.crsspctrm)] * [real(phfac); imag(phfac)];
  % the dot product only works when freq.crsspctrm is 1d, the below works with 2d
  % (rpt_chan)
  tmp = permute(cat(3, real(four_onestim), imag(four_onestim)), [1 3 2]);
  feats = squeeze(pagemtimes(tmp, [real(phfac); imag(phfac)]));

  % overall strength of projection along ph, averaged across trials
  act_coh_onestim(k,:) = mean(feats, 1);
end

% figure out peak phase by taking max-variance (or max-range?)
topovar = var(act_coh_onestim, [], 2);

[~,peakph_ind] = max(topovar);
peakph = ph_coh(peakph_ind);

%assert(peakph < pi); % max should return the first peak, but we expect another one of equal height >= pi
% assertion sometimes fails for some rounding issues, simply take mod(pi)
% instead
peakph = mod(peakph, pi);

%% now project two stim case onto peak and 90deg shifted phase

% fourier coefficients relative to tagging channel
four_twostim = freq_twostim.fourierspctrm(:,1:end-1,60) ./ freq_twostim.fourierspctrm(:,refchanind,60);

% project onto peak phase
phfac = exp(1j*peakph);
tmp = permute(cat(3, real(four_twostim), imag(four_twostim)), [1 3 2]);
feats = squeeze(pagemtimes(tmp, [real(phfac); imag(phfac)]));
act_peakph_twostim = mean(feats, 1);

% project onto 90deg shifted phase
phfac = exp(1j*(peakph + pi/2));
tmp = permute(cat(3, real(four_twostim), imag(four_twostim)), [1 3 2]);
feats = squeeze(pagemtimes(tmp, [real(phfac); imag(phfac)]));
act_shiftph_twostim = mean(feats, 1);

%% for illustration: plot topos at several phases

clim = max(act_coh_onestim(:));

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
cfg.colormap = '*RdBu';
cfg.zlim = [-clim clim];
cfg.gridscale = 100;

phases_to_plot = [peakph-pi/4 peakph peakph+pi/4 peakph+pi/2 peakph+3*pi/4];
nph = numel(phases_to_plot);

f = figure('defaultaxesfontsize', 12, 'position', [0 0 1280 800]);
for k = 1:nph
    ph = phases_to_plot(k);
    [~,phind] = min(abs(ph_coh-ph)); % cannot use find() because may not be exact match
    assert(abs(ph_coh(phind)-ph) < 1e-10); % but should be extremely close

    subtightplot(2,nph,k);
    tmp.avg = act_coh_onestim(phind,:)';
    ft_topoplotER(cfg, tmp);
    title(sprintf('one stim, phase = %.3g', ph));
end

clim = max([act_peakph_twostim(:); act_shiftph_twostim(:)]);
cfg.zlim = [-clim clim];

% also plot topos for two stim cases
subtightplot(2, nph, nph+1);
tmp.avg = act_peakph_twostim';
ft_topoplotER(cfg, tmp);
title(sprintf('two stim, phase = %.3g', peakph));

subtightplot(2, nph, nph+2);
tmp.avg = act_shiftph_twostim';
ft_topoplotER(cfg, tmp);
title(sprintf('two stim, phase = %.3g', peakph+pi/2));

% also plot var(topo) per phases
subtightplot(2, nph, [nph+4 nph+5]);
plot(ph_coh, topovar, 'k');
xlim([0 2*pi]);
for k = 1:nph
    xline(phases_to_plot(k), 'k:');
end
xlabel('Phase lag (rad)');
ylabel('Variance across channels');
set(gca, 'box', 'off');

exportgraphics(f, sprintf('%s/illustrations-phaseproject-pipeline.pdf', plotdir),...
    'Resolution', 150, 'contenttype', 'vector');

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
tl_peak.avg = act_peakph_twostim';
tl_peak.grad = ft_convert_units(freq_onestim.grad, 'mm');
tl_shift = tl_peak;
tl_shift.avg = act_shiftph_twostim';

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

%% for illustration: plot two resulting dipole fits

colors = brewermap(2, 'Set2');

f = figure();
plot_volume_dipoles([pos_peak_mni; pos_shift_mni],...
  'colors', colors, 'sphereradius', 5, 'slicepos', [0 -88 -9],... % calcarine sulcus, central
  'plotstems', 1);
axis padded;
% set(f, 'color', 'none');
% set(gca, 'color', 'none');

set(findall(gca, 'Type', 'Line'),'LineWidth',1);

exportgraphics(f, sprintf('%s/illustrations-phaseproject-dipoles.png', plotdir),...
    'Resolution', 300, 'backgroundcolor', 'none');
