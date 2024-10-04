% Copyright 2024 Eelke Spaak, Donders Institute.
% See https://github.com/Spaak/rift-phase-and-visibility for readme/license.
% Belongs with:
% Spaak, E., Bouwkamp, F. G., & de Lange, F. P. (2024). Perceptual foundation and extension
% to phase tagging for rapid invisible frequency tagging (RIFT). Imaging Neuroscience, 2, 1–14.
% https://doi.org/10.1162/imag_a_00242

function RunBlinkTrial(ptb, stim)

ptb.btsi.sendTrigger(stim.trig.TRI_BLINK);

% draw blink stimulus in all four quadrants of buffer
for quadrant = 1:4
    Screen('DrawTexture', ptb.win, stim.tex.blink, [], ...
        MakeOffsetRect(ptb, stim, 0, 0, quadrant));
end

Screen('Flip', ptb.win);

WaitSecs(stim.dur_blink);

end