% Copyright 2024 Eelke Spaak, Donders Institute.
% See https://github.com/Spaak/rift-phase-and-visibility for readme/license.
% Belongs with:
% Spaak, E., Bouwkamp, F. G., & de Lange, F. P. (2024). Perceptual foundation and extension
% to phase tagging for rapid invisible frequency tagging (RIFT). Imaging Neuroscience, 2, 1–14.
% https://doi.org/10.1162/imag_a_00242

function x = make_square_wave(len, period)

assert(mod(period, 2) == 0);

% start with a half band and repeat full cycle until we have enough
x = [ones(round(period/4), 1); repmat([zeros(period/2, 1); ones(period/2, 1)], ceil(len/period), 1)];
x = x(1:len);

end