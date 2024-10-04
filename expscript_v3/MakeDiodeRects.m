% Copyright 2024 Eelke Spaak, Donders Institute.
% See https://github.com/Spaak/rift-phase-and-visibility for readme/license.
% Belongs with:
% Spaak, E., Bouwkamp, F. G., & de Lange, F. P. (2024). Perceptual foundation and extension
% to phase tagging for rapid invisible frequency tagging (RIFT). Imaging Neuroscience, 2, 1–14.
% https://doi.org/10.1162/imag_a_00242

function diode_rects = MakeDiodeRects(ptb, stim)

diode_rects = zeros(4, 4);
stim_sz = size(stim.grating, 1);
for quadrant = 1:4
    diode_rects(quadrant,:) = MakeOffsetRect(ptb, stim,...
        -ptb.win_w/4+stim_sz/2, ptb.win_h/4-stim_sz/2, quadrant);
end

end