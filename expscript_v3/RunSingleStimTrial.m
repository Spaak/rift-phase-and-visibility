function fliptimes = RunSingleStimTrial(ptb, stim, dur_bsl, stim_rot,...
    tag_sig, trigval, tag_type)

stim_tex = stim.tex.grating;

% initialize drawing rects (centered on physical screen)
rects = zeros(4, 4);
for quadrant = 1:4
    rects(quadrant,:) = MakeOffsetRect(ptb, stim, 0, 0, quadrant);
end
diode_rects = MakeDiodeRects(ptb, stim); % rects for diode tracking square

% fixation baseline
Screen('DrawTextures', ptb.win, stim.tex.fix, [], rects');
Screen('Flip', ptb.win);
WaitSecs(dur_bsl);

% store old blend function for restoring later
[~, ~, mask_old] = Screen('BlendFunction', ptb.win);

ptb.btsi.sendTrigger(trigval);

%allimgs = {};
% tagged presentation loop
vbl = []; % the flip vbl timestamp
fliptimes = nan(1, numel(tag_sig)/12);
flipind = 1;
% tag_sig = repmat([0 0.25 0.5 1], [1 6]);
for phys_frame_ind = 1:numel(tag_sig)
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
    if tag_type == 1
        % luminance tagging between 0 and 100%: multiply intensity with
        % tagging signal
        % (black stays black, white goes between 0-100%)
        color_mod = ones(1, 3) * 255 * tag_sig(phys_frame_ind);
        Screen('DrawTexture', ptb.win, stim_tex, [], rects(quadrant,:),...
            stim_rot, [], [], color_mod);
    elseif tag_type == 2
        % luminance tagging between 50% and 100%: scale down intensity
        % signal, add 50% offset, and multiply
        % (black stays black, white goes between 50-100%)
        color_mod = ones(1, 3) * 128 * tag_sig(phys_frame_ind) + 127;
        Screen('DrawTexture', ptb.win, stim_tex, [], rects(quadrant,:),...
            stim_rot, [], [], color_mod);
    elseif tag_type == 3
        % luminance tagging with offset
        % draw white stim with opacity varying between 0-50% on top of
        % actual stimulus, resulting in stimulus having black go between
        % 0-50%, and white between 50-100%
        Screen('DrawTexture', ptb.win, stim_tex, [], rects(quadrant,:),...
            stim_rot);
        Screen('DrawTexture', ptb.win, stim.tex.lum_disc, [], rects(quadrant,:),...
            stim_rot, [], tag_sig(phys_frame_ind)/2);
    elseif tag_type == 4
        % contrast tagging
        % black goes between 50% and 0%, while white goes between 50% and
        % 100%
        Screen('DrawTexture', ptb.win, stim_tex, [], rects(quadrant,:),...
            stim_rot, [], tag_sig(phys_frame_ind));
    else
        error('invalid tagging type specified');
    end
        
    
    % draw diode tracking square
    Screen('DrawTexture', ptb.win, stim.tex.diode_track, [],...
        diode_rects(quadrant,:), [], [], [], 255*tag_sig(phys_frame_ind));
    
    % flip if necessary (every 12 physical frames)
    if phys_frame_ind > 1 && mod(phys_frame_ind, 12) == 0
        % draw fixation dot in every quadrant
        Screen('BlendFunction', ptb.win, [], [], mask_old);
        Screen('DrawTextures', ptb.win, stim.tex.fix, [], rects');
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

%     % for debugging
%     doclear = phys_frame_ind > 1 && mod(phys_frame_ind, 12) == 0;
%     fprintf('flipping, tag=%.4g %%...', tag_sig(phys_frame_ind)*100);
%     Screen('Flip', ptb.win, 0, double(~doclear));
%     fprintf('flipped.\n');
%     
%     % store image
%     allimgs{end+1} = Screen('GetImage', ptb.win);
%     WaitSecs(0.1);
% %     KbWait();
end

% assignin('base', 'allimgs', allimgs);
% assignin('base', 'tag_sig', tag_sig(1:24));

% restore blend function
Screen('BlendFunction', ptb.win, [], [], mask_old);

end