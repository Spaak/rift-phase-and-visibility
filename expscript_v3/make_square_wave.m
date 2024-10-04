function x = make_square_wave(len, period)

assert(mod(period, 2) == 0);

% start with a half band and repeat full cycle until we have enough
x = [ones(round(period/4), 1); repmat([zeros(period/2, 1); ones(period/2, 1)], ceil(len/period), 1)];
x = x(1:len);

end