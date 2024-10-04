function trg = MakeOnsetTrig(num_stims, tag_type, random_phases, use_phasetag, is_attn, use_old_version)

if nargin < 6
    use_old_version = false;
end


num_stims = num_stims-1;
tag_type = tag_type-1;

% encode as binary string
str = arrayfun(@dec2bin, [num_stims, tag_type, random_phases, use_phasetag, is_attn], 'uniformoutput', false);

if ~use_old_version
    % for sub001 and earlier pilots, we did not treat tag type as
    % two-character binary string properly
    if numel(str{2}) < 2
        % prepend 0 if needed
        str{2} = ['0' str{2}];
    end
end

str = cat(2, str{:}, '1'); % always start with 1 in lowest bit

trg = bin2dec(str);

end