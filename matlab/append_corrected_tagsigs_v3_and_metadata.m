function [data,meta_columns] = append_corrected_tagsigs_v3_and_metadata(data, stim)

% basic check that data is ordered consecutively and has all 750 trials
% 750 trials = all passive viewing
assert(isequal(data.trialinfo(:,1), (1:750)'));

% attentional trials are handled in the _attnblocks version of this file

%% determine ramp up points

% simply check when the diode signal ramps up. This is not
% exactly perfect, because some trials might start with tagging phase -pi,
% resulting in zero contrast at stimulus onset. But it works very well in
% practice

chanind = match_str(data.label, 'UADC001');

ntri = numel(data.trial);
ramppoint = nan(ntri, 1);
for k = 1:ntri
  dat = data.trial{k}(chanind,:);
  tim = data.time{k};
  inds = tim > -0.2 & tim < -0.05;
  mu = mean(dat(inds));
  sd = std(dat(inds));
  zdat = (dat - mu) ./ sd;
  
  % use a different threshold depending on tagging signal intensity
  % needed because luminance-1 tagging (black background) results in much
  % higher signal than other tagging methods (gray background)
  if max(abs(zdat(:))) > 100
    zthresh = 50;
  else
    zthresh = 2;
  end
  
  % for one subject (8) the ramp starts downward somehow
  if mean(zdat(tim>0)) < mean(zdat(tim<0))
    assert(contains(data.cfg.dataset, 'sub-008') ||...
      contains(data.cfg.dataset, 'sub-006'));
    fprintf('using abs z-score for ramp detection in trial %d because flank appears downgoing\n', k);
    zdat = abs(zdat);
  end
  ramppoint(k) = find(zdat > zthresh & tim > 0, 1, 'first');
end

%% now create time-corrected tagging signals

meg_dt = 1/1200;
flip_dt = 1/120;
timax_tag_meg = meg_dt:meg_dt:stim.dur_stim_passive;

% for reference
% MakeOnsetTrig(num_stims, tag_type, random_phases, use_phasetag, is_attn, use_old_version)

% also construct metadata matrix
meta_columns = {'id', 'trig', 'numstim', 'tag_type', 'random_phases',...
    'use_phasetag', 'is_attn', 'freq1', 'freq2', 'phase1', 'phase2',...
    'stimrot1', 'stimrot2', 'attside', 'has_att_dim', 'respside', 'rt'};
metadata = nan(numel(data.trial), numel(meta_columns)-2);

meg_tri = 1;
for blk = 1:12%numel(stim.blocks) % first 12 blocks is passive viewing TODO add attn
  for tri = 1:size(stim.blocks{blk}.dur_bsl,1)
    tagsig = nan(2, numel(data.time{tri}));
    for tagind = 1:2
      if tagind > numel(stim.blocks{blk}.tag_freqs)
        break;
      end
      % express stored tagging signal at sampling rate equal to MEG (1200 Hz);
      % necessary because the stored tagging signal is sampled at 1440 Hz
      freq = stim.blocks{blk}.tag_freqs(tagind);
      stored_tag_megdt_raw = cos(2*pi*freq.*timax_tag_meg + stim.blocks{blk}.phases(tri,tagind)) / 2 + 0.5;

      % correct tagging signal for missed flips
      % we are here assuming that the first flip happened at time 0 (will be
      % corrected for later)
      flips = stim.blocks{blk}.fliptimes(tri,:);

      % keep two indexing variables: one referencing the original raw tagging
      % signal, one referencing where the next chunk of tag signal should be
      % stored in the corrected signal
      start_samp_raw = flip_dt/meg_dt+1;
      start_samp_corr = start_samp_raw;
      stored_tag_megdt = nan(size(stored_tag_megdt_raw));
      stored_tag_megdt(1:start_samp_corr-1) = stored_tag_megdt_raw(1:start_samp_raw-1);
      for k = 2:numel(flips)
        dt = flips(k)-flips(k-1)-flip_dt;
        if dt > 0.001 % missed by more than 1 ms 
          fprintf('flip missed by %.3g ms, block %3d, trial %3d\n', dt*1000, blk, tri);
          pad = round(dt/meg_dt);
          stored_tag_megdt(start_samp_corr:start_samp_corr+pad) = stored_tag_megdt(start_samp_corr-1);
          start_samp_corr = start_samp_corr + pad + 1;
        end

        stored_tag_megdt(start_samp_corr:start_samp_corr+flip_dt/meg_dt) = ...
          stored_tag_megdt_raw(start_samp_raw:start_samp_raw+flip_dt/meg_dt);
        start_samp_corr = start_samp_corr + flip_dt/meg_dt + 1;
        start_samp_raw = start_samp_raw + flip_dt/meg_dt + 1;

        if start_samp_raw > numel(stored_tag_megdt_raw)
          assert(~any(isnan(stored_tag_megdt)));
          break;
        end
      end

      % start expressing the recorded tagging signal from a particular sample
      % onwards (given by the ramp point computed previously)
      start_samp = ramppoint(meg_tri);
      ntim_meg = numel(data.time{meg_tri});
      dat = zeros(1, ntim_meg);
      dat(start_samp:ntim_meg) = stored_tag_megdt(1:(ntim_meg-start_samp+1));
      tagsig(tagind,:) = dat;
    end
    
    data.trial{meg_tri}(end+1:end+2,:) = tagsig;
    
    % also construct metadata matrix
    
    % for reference:
%     meta_columns = {'id', 'trig', 'numstim', 'tag_type', 'random_phases',...
%     'use_phasetag', 'is_attn', 'freq1', 'freq2', 'phase1', 'phase2',...
%     'stimrot1', 'stimrot2', 'att_side', 'att_dim_tim', 'respside', 'rt'};
    % will be appended after the trial ID and trigger value columns

    stimblk = stim.blocks{blk};
    nstim = size(stimblk.phases, 2);
    metadata(meg_tri, 1) = nstim;
    metadata(meg_tri, 2) = stimblk.tag_type;
    metadata(meg_tri, 3) = stimblk.random_phases;
    metadata(meg_tri, 4) = nstim > 1 && stimblk.use_phasetag;
    metadata(meg_tri, 5) = isfield(stimblk, 'att_side');
    metadata(meg_tri, 6) = stimblk.tag_freqs(1);
    metadata(meg_tri, 8) = stimblk.phases(tri, 1);
    metadata(meg_tri, 10) = stimblk.stim_rots(tri, 1);
    if nstim > 1
      metadata(meg_tri, 7) = stimblk.tag_freqs(2);
      metadata(meg_tri, 9) = stimblk.phases(tri, 2);
      metadata(meg_tri, 11) = stimblk.stim_rots(tri, 2);
    end
    if isfield(stimblk, 'att_side')
        metadata(meg_tri,12) = stimblk.att_side(tri);
        metadata(meg_tri,13) = stimblk.dim_tim(tri);
        % TODO: extract responses and RT from UPPT002 channel
    end

    meg_tri = meg_tri + 1;
  end
end

assert(meg_tri==751);

% append labels for new channels
data.label = [data.label; {'tag1', 'tag2'}'];

data.trialinfo(:,end+1:end+size(metadata, 2)) = metadata;


end