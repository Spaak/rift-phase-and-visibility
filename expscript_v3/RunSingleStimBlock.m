function blockstim = RunSingleStimBlock(ptb, stim, tag_freq, tag_type,...
    random_phases)

% determine trigger value based on conditions
trigval = MakeOnsetTrig(1, tag_type, random_phases, 0, 0);

% number of trials in this block
ntri = stim.numtri_block_single;

blockstim = [];
blockstim.tag_freqs = tag_freq;
blockstim.tag_type = tag_type;
blockstim.random_phases = random_phases;

% initialize tagging signals and trigger to send per trial
timax = stim.dt:stim.dt:stim.dur_stim_passive;
assert(mod(numel(timax), 12) == 0);
if random_phases
    blockstim.phases = rand(ntri, 1) * 2*pi;
else
    % for fixed phases, always use pi/2, this ensures
    % equal total luminance between tagged and non-tagged blocks
    blockstim.phases = ones(ntri, 1) * pi/2;
end
blockstim.tag_sigs = cos(2*pi*tag_freq*timax + blockstim.phases) / 2 + 0.5;

% initialize duration of baseline periods
blockstim.dur_bsl = rand(ntri, 1) * (stim.dur_bsl_max-stim.dur_bsl_min) + stim.dur_bsl_min;

% initialize gabor orientations
blockstim.stim_rots = repmat(stim.param.grating_ang', ntri/numel(stim.param.grating_ang), 1);
assert(blockstim.stim_rots(end) == stim.param.grating_ang(end));
%blockstim.stim_rots = shuffle_no_repeats(blockstim.stim_rots);
blockstim.stim_rots = blockstim.stim_rots(randperm(ntri));

% before which trials to add a blink/button press "trial"
blnktri = randi([4, 6]);
while blnktri(end)+5 < ntri
    blnktri(end+1) = blnktri(end) + randi([4, 6]);      
end
blockstim.blink_tri_before = false(ntri, 1);
blockstim.blink_tri_before(blnktri) = 1;

% log onset times of trials
blockstim.tri_onsets = nan(ntri, 1);
blockstim.blink_tri_onsets = [];

% log all flip timestamps during tagging loops
blockstim.fliptimes = nan(ntri, numel(timax)/12);

% trial loop
for tri = 1:ntri
    if blockstim.blink_tri_before(tri)
        blockstim.blink_tri_onsets(end+1) = GetSecs();
        RunBlinkTrial(ptb, stim);
    end
    
    blockstim.tri_onsets(tri) = GetSecs();
    blockstim.fliptimes(tri,:) = RunSingleStimTrial(ptb, stim, blockstim.dur_bsl(tri),...
        blockstim.stim_rots(tri), blockstim.tag_sigs(tri,:), trigval, tag_type);
end

end