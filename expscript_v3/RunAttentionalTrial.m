function fliptimes = RunAttentionalTrial(ptb, stim, dur_bsl, stim_rots,...
    tag_sigs, trigval, tag_type, att_side)

stim_tex = stim.tex.grating;

% initialize drawing rects (either side of center on physical screen)
% buffer quadrant X [stim1, stim2, fix] X rect
rects = zeros(4, 3, 4);
offset = stim.deg2pix(stim.param.grating_exc);
for quadrant = 1:4
    rects(quadrant,1,:) = MakeOffsetRect(ptb, stim, -offset, 0, quadrant);
    rects(quadrant,2,:) = MakeOffsetRect(ptb, stim, offset, 0, quadrant);
    rects(quadrant,3,:) = MakeOffsetRect(ptb, stim, 0, 0, quadrant);
end
diode_rects = MakeDiodeRects(ptb, stim); % rects for diode tracking square

% fixation baseline (fix dot only)
Screen('DrawTextures', ptb.win, stim.tex.fix, [], squeeze(rects(:,3,:))');
Screen('Flip', ptb.win);
WaitSecs(dur_bsl);

% attentional cue (L/R arrow)
Screen('DrawTextures', ptb.win, stim.tex.arrows(att_side), [], squeeze(rects(:,3,:))');
Screen('Flip', ptb.win);
WaitSecs(stim.dur_attcue);

% store old blend function for restoring later
[~, ~, mask_old] = Screen('BlendFunction', ptb.win);

ptb.btsi.sendTrigger(trigval);

% tagged presentation loop
vbl = []; % the flip vbl timestamp
fliptimes = nan(1, size(tag_sigs, 2)/12);
flipind = 1;
for phys_frame_ind = 1:size(tag_sigs, 2)
    % which quadrant are we going to draw in?
    % quadrant will increase by 1 every physical frame and reset after
    % 4 physical frames
    quadrant = mod(phys_frame_ind-1, 4) + 1;
    
    % select the proper colour channel to draw into
    % colorchan will increase by 1 every 4 physical frames and reset after
    % 12 physical frames
    colorchan = mod(floor((phys_frame_ind-1)/4), 3) + 1;
    colmask = zeros(4,1);
    colmask(colorchan) = 1;
    Screen('BlendFunction', ptb.win, [], [], colmask);
    
    % draw the stimulus with the specified tagging type
    thisrects = squeeze(rects(quadrant,1:2,:))';
    if tag_type == 1
        % luminance tagging between 0 and 100%: multiply intensity with
        % tagging signal
        % (black stays black, white goes between 0-100%)
        color_mod = ones(3, 1) * 255 .* tag_sigs(:,phys_frame_ind)';
        Screen('DrawTextures', ptb.win, stim_tex, [], thisrects,...
            stim_rots, [], [], color_mod);
    elseif tag_type == 2
        % luminance tagging between 50% and 100%: scale down intensity
        % signal, add 50% offset, and multiply
        % (black stays black, white goes between 50-100%)
        color_mod = ones(3, 1) * 128 .* tag_sigs(:,phys_frame_ind)' + 127;
        Screen('DrawTextures', ptb.win, stim_tex, [], thisrects,...
            stim_rots, [], [], color_mod);
    elseif tag_type == 3
        % luminance tagging with offset
        % draw white stim with opacity varying between 0-50% on top of
        % actual stimulus, resulting in stimulus having black go between
        % 0-50%, and white between 50-100%
        Screen('DrawTextures', ptb.win, stim_tex, [], thisrects,...
            stim_rots);
        Screen('DrawTextures', ptb.win, stim.tex.lum_disc, [], thisrects,...
            stim_rots, [], tag_sigs(:,phys_frame_ind)/2);
    elseif tag_type == 4
        % contrast tagging
        % black goes between 50% and 0%, while white goes between 50% and
        % 100%
        Screen('DrawTextures', ptb.win, stim_tex, [], thisrects,...
            stim_rots, [], tag_sigs(:,phys_frame_ind));
    else
        error('invalid tagging type specified');
    end
    
    % draw diode tracking square (tracks first tagging signal)
    Screen('DrawTexture', ptb.win, stim.tex.diode_track, [],...
        diode_rects(quadrant,:), [], [], tag_sigs(1,phys_frame_ind));
    
    % flip if necessary (every 12 physical frames)
    if phys_frame_ind > 1 && mod(phys_frame_ind, 12) == 0
        % draw fixation dot in every quadrant
        Screen('BlendFunction', ptb.win, [], [], mask_old);
        Screen('DrawTextures', ptb.win, stim.tex.fix, [], squeeze(rects(:,3,:))');
        if ~isempty(vbl)
            vbl = Screen('Flip', ptb.win, vbl+ptb.ifi/2);
        else
            % the first time we're flipping we don't have a previous
            % timestamp yet
            vbl = Screen('Flip', ptb.win);
        end
        fliptimes(flipind) = vbl;
        flipind = flipind + 1;
    end
end

% restore blend function
Screen('BlendFunction', ptb.win, [], [], mask_old);

end