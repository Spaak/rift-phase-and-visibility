% Copyright 2024 Eelke Spaak, Donders Institute.
% See https://github.com/Spaak/rift-phase-and-visibility for readme/license.
% Belongs with:
% Spaak, E., Bouwkamp, F. G., & de Lange, F. P. (2024). Perceptual foundation and extension
% to phase tagging for rapid invisible frequency tagging (RIFT). Imaging Neuroscience, 2, 1–14.
% https://doi.org/10.1162/imag_a_00242

function blockstim = RunAXBBlock(ptb, stim, tag_freqs, tag_type, use_phasetag)

% number of trials in this block
ntri = stim.numtri_block_axb;

blockstim = [];
blockstim.tag_type = tag_type;
blockstim.use_phasetag = use_phasetag;

% randomly assign the two frequencies to left or right per trial
blockstim.tag_freqs = repmat(tag_freqs, ntri, 1);
for k = 1:ntri
    if rand() < 0.5
        blockstim.tag_freqs(k,:) = blockstim.tag_freqs(k,[2 1]);
    end
end

% which stimulus (A (left, 1) or B (right, 2) will be presented as X?
blockstim.probe_stim = randi(2, ntri, 1);

% initialize tagging signals and trigger to send per trial
timax = stim.dt:stim.dt:stim.dur_stim_axb;
assert(mod(numel(timax), 12) == 0);
if use_phasetag
    assert(tag_freqs(1) == tag_freqs(2));
    % set one stimulus to a random phase, and the other to a 90deg (pi/2)
    % offset
    blockstim.phases = rand(ntri, 1) * 2*pi;
    blockstim.phases(:,2) = blockstim.phases(:,1) + pi/2;
    trigval = stim.trig.TRI_AXB_PHASES;
elseif tag_freqs(1) == 0
    % one stimulus untagged, always phase pi/2
    blockstim.phases = rand(ntri, 2) * 2*pi;
    blockstim.phases(blockstim.tag_freqs==0) = pi/2;
    trigval = stim.trig.TRI_AXB_TAGNOTAG;
else
    % two different freqs
    assert(tag_freqs(1) ~= tag_freqs(2) && all(tag_freqs > 0));
    blockstim.phases = rand(ntri, 2) * 2*pi;
    trigval = stim.trig.TRI_AXB_FREQS;
end
blockstim.tag_sigs = cos(blockstim.phases + ...
    2*pi*blockstim.tag_freqs.*reshape(timax, [1 1 numel(timax)])) / 2 + 0.5;

% which stimulus to track using the photo diode?
% (we never want to track the non-tagged stim)
blockstim.tracked_stim = ones(ntri, 1);
blockstim.tracked_stim(blockstim.tag_freqs(:,1)==0) = 2;

% initialize duration of baseline periods
blockstim.dur_bsl = rand(ntri, 1) * (stim.dur_bsl_max-stim.dur_bsl_min) + stim.dur_bsl_min;

% initialize gabor orientations (all stims on screen have same orientation
% in AXB trials)
blockstim.stim_rot = repmat(stim.param.grating_ang', ntri/numel(stim.param.grating_ang), 1);
assert(blockstim.stim_rot(end) == stim.param.grating_ang(end));
blockstim.stim_rot = shuffle_no_repeats(blockstim.stim_rot);

% log onset times of trials and responses
blockstim.tri_onsets = nan(ntri, 1); 
blockstim.responses = nan(ntri, 1);
blockstim.rts = nan(ntri, 1);

% log all flip timestamps during tagging loops
blockstim.fliptimes = nan(ntri, numel(timax)/12);

% trial loop
for tri = 1:ntri
    blockstim.tri_onsets(tri) = GetSecs();
    [blockstim.responses(tri), blockstim.rts(tri), blockstim.fliptimes(ntri,:)] = ...
        RunAXBTrial(ptb, stim, blockstim.dur_bsl(tri),...
        blockstim.stim_rot(tri,:), squeeze(blockstim.tag_sigs(tri,:,:)),...
        blockstim.probe_stim(tri), blockstim.tracked_stim(tri), trigval,...
        tag_type);
end

end