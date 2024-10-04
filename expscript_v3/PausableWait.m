% Copyright 2024 Eelke Spaak, Donders Institute.
% See https://github.com/Spaak/rift-phase-and-visibility for readme/license.
% Belongs with:
% Spaak, E., Bouwkamp, F. G., & de Lange, F. P. (2024). Perceptual foundation and extension
% to phase tagging for rapid invisible frequency tagging (RIFT). Imaging Neuroscience, 2, 1–14.
% https://doi.org/10.1162/imag_a_00242

function PausableWait(ptb, secs)

untiltime = GetSecs() + secs;

while GetSecs() < untiltime
    [keydown, ~, keycode] = KbCheck();
    if keydown && keycode(80) % button p - pause
        PauseScreen(ptb);
        
        % re-start the waiting time if we've paused
        untiltime = GetSecs() + secs;
        Screen('Flip', ptb.win); % one blank frame to prompt the subject
        DrawFixationDot(ptb, 1);
    end
    WaitSecs(0.001);
end
    
end