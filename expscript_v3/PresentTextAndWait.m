% Copyright 2024 Eelke Spaak, Donders Institute.
% See https://github.com/Spaak/rift-phase-and-visibility for readme/license.
% Belongs with:
% Spaak, E., Bouwkamp, F. G., & de Lange, F. P. (2024). Perceptual foundation and extension
% to phase tagging for rapid invisible frequency tagging (RIFT). Imaging Neuroscience, 2, 1–14.
% https://doi.org/10.1162/imag_a_00242

function PresentTextAndWait(ptb, stim, txt, use_bitsi)

txt = WrapString(txt, 65);
for quadrant = 1:4
    DrawFormattedText(ptb.win, WrapString(txt, 5650), 'center', 'center',...
        255, [], [], [], 1.1, [], MakeOffsetRect(ptb, stim, 0, 0, quadrant));
end

Screen('Flip', ptb.win);
WaitSecs(0.5);

if nargin > 3 && use_bitsi
    ptb.btsi.clearResponses();
    [~, ~] = ptb.btsi.getResponse(Inf, true);
else
    % wait for keyboard input (from experimenter)
    [~, ~, ~] = KbWait([], 3); % wait for press and release
end

end