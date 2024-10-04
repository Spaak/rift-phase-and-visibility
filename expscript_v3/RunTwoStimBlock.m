function blockstim = RunTwoStimBlock(ptb, stim, tag_freqs, tag_type,...
    random_phases, use_phasetag)

% determine trigger value based on conditions
trigval = MakeOnsetTrig(2, tag_type, random_phases, use_phasetag, 0);

% number of trials in this block
ntri = stim.numtri_block_two;

blockstim = [];
blockstim.tag_freqs = tag_freqs;
blockstim.tag_type = tag_type;
blockstim.random_phases = random_phases;
blockstim.use_phasetag = use_phasetag;

% initialize tagging signals and trigger to send per trial
timax = stim.dt:stim.dt:stim.dur_stim_passive;
assert(mod(numel(timax), 12) == 0);
if random_phases && use_phasetag
    assert(tag_freqs(1) == tag_freqs(2));
    % set one stimulus to a random phase, and the other to a 90deg (pi/2)
    % offset
    blockstim.phases = rand(ntri, 1) * 2*pi;
    blockstim.phases(:,2) = blockstim.phases(:,1) + pi/2;
elseif random_phases
    assert(tag_freqs(1) ~= tag_freqs(2));
    % both stims random phase
    blockstim.phases = rand(ntri, 2) * 2*pi;
else
    assert(~use_phasetag);
    blockstim.phases = ones(ntri, 2) * pi/2;
end
blockstim.tag_sigs = cos(blockstim.phases + ...
    reshape(2*pi*tag_freqs'*timax, [1, 2, numel(timax)])) / 2 + 0.5;

% initialize duration of baseline periods
blockstim.dur_bsl = rand(ntri, 1) * (stim.dur_bsl_max-stim.dur_bsl_min) + stim.dur_bsl_min;

% initialize gabor orientations
% in the two-stim case, make sure that each given orientation X in stim 1
% is accompanied by an equal distribution of orientations Y in stim 2
rots = CombVec(stim.param.grating_ang, stim.param.grating_ang)';
blockstim.stim_rots = repmat(rots, ntri/size(rots, 1), 1);
assert(all(blockstim.stim_rots(end,:) == stim.param.grating_ang(end)));
blockstim.stim_rots = blockstim.stim_rots(randperm(size(blockstim.stim_rots,1)),:);

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
    blockstim.fliptimes(tri,:) = RunTwoStimTrial(ptb, stim, blockstim.dur_bsl(tri),...
        blockstim.stim_rots(tri,:), squeeze(blockstim.tag_sigs(tri,:,:)), trigval,...
        tag_type);
end

end