% Copyright 2024 Eelke Spaak, Donders Institute.
% See https://github.com/Spaak/rift-phase-and-visibility for readme/license.
% Belongs with:
% Spaak, E., Bouwkamp, F. G., & de Lange, F. P. (2024). Perceptual foundation and extension
% to phase tagging for rapid invisible frequency tagging (RIFT). Imaging Neuroscience, 2, 1–14.
% https://doi.org/10.1162/imag_a_00242

function [num_stims, stim_type, tag_type, random_phases, use_phasetag] = ...
    DecodeOnsetTrig(trg)

str = dec2bin(trg, 7);
assert(numel(str) == 7);

num_stims = bin2dec(str(1)) + 1;
stim_type = bin2dec(str(2));
tag_type = bin2dec(str(3:4)) + 1;
random_phases = bin2dec(str(5));
use_phasetag = bin2dec(str(6));

end