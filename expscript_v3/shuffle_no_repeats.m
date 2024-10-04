function y = shuffle_no_repeats(x)
% Fisher-Yates shuffle algorithm, with the added constraint that no two
% numbers can repeat.

y = [];
while ~isempty(x)
    ind = randi(numel(x)); % initial candidate index to draw
    while ~isempty(y) && x(ind) == y(end) && ~all(x == y(end))
        % if the number we would draw is equal to the one at the end of y
        ind = randi(numel(x)); % draw again
    end
    
    % handle special case of only a few elements left in x that happen to
    % be identical to y(end)
    if ~isempty(y) && all(x == y(end))
        % find suitable positions to insert
        suitable = false(numel(y), 1);
        val = x(1);
        for ind = 1:numel(y)
            if (ind == 1 && y(1) ~= val) || (ind > 1 && y(ind-1) ~= val && y(ind) ~= val)
                suitable(ind) = true;
            end
        end
        
        % choose randomly from the suitable indices
        inds = find(suitable);
        inds = inds(randi(numel(inds), [numel(x) 1]));
        for k = 1:numel(inds)
            ind = inds(k);
            if ind == 1
                y = [val; y];
            else
                y = [y(1:ind-1); val; y(ind:end)];
            end
        end
        break;
    else
        y = [y; x(ind)]; % append the new number to y
        x(ind) = []; % remove the appended number from x
    end
end

end