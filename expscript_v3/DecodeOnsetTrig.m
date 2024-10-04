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