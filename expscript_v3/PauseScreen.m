% Copyright 2024 Eelke Spaak, Donders Institute.
% See https://github.com/Spaak/rift-phase-and-visibility for readme/license.
% Belongs with:
% Spaak, E., Bouwkamp, F. G., & de Lange, F. P. (2024). Perceptual foundation and extension
% to phase tagging for rapid invisible frequency tagging (RIFT). Imaging Neuroscience, 2, 1–14.
% https://doi.org/10.1162/imag_a_00242

function PauseScreen(ptb)

while true
    [keydown, ~, keycode] = KbCheck();
    if keydown && keycode(82) % button r - resume
        return;
    elseif keydown && keycode(27) % button ESC - escape, quit experiment
        Screen('CloseAll');
        error('experiment aborted by pressing ESC key');
    elseif keydown && keycode(69) % button e - eyelink
        EyelinkDoTrackerSetup(ptb.eye);
    
        WaitSecs(0.1);
        Eyelink('StartRecording');
    end
    DrawFormattedText(ptb.win, 'One moment please...', ptb.win_w/2-250,...
        ptb.win_h/2-250, 255);
    DrawFixationDot(ptb, 1);
    WaitSecs(0.01);
end

end