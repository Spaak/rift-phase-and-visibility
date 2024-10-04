% Copyright 2024 Eelke Spaak, Donders Institute.
% See https://github.com/Spaak/rift-phase-and-visibility for readme/license.
% Belongs with:
% Spaak, E., Bouwkamp, F. G., & de Lange, F. P. (2024). Perceptual foundation and extension
% to phase tagging for rapid invisible frequency tagging (RIFT). Imaging Neuroscience, 2, 1–14.
% https://doi.org/10.1162/imag_a_00242

function rect = MakeOffsetRect(ptb, stim, dx, dy, quadrant)
% Create a destination rectangle suitable for drawing a Gabor, at a
% particular x and y offset from the center of the screen. Size of the
% rectangle equals the intrinsic size of the Gabor patch texture.
% The optional quadrant argument additionally shifts the rectangle relative
% not to the center of the screen, but to the center of the top left (1),
% top right (2), bottom left (3), or bottom right (4) quadrant. This is
% useful when using ProPIXX rapid mode.

% PTB rectangles have (left top right bottom) spec

stim_sz = size(stim.grating, 1);

if nargin < 4
    % origin is center of actual screenbuffer
    rect = [ptb.win_w/2-stim_sz/2+dx, ptb.win_h/2-stim_sz/2+dy, ptb.win_w/2+stim_sz/2+dx, ptb.win_h/2+stim_sz/2+dy];
    
elseif quadrant == 1
    % top left quadrant
    rect = [ptb.win_w/4-stim_sz/2+dx, ptb.win_h/4-stim_sz/2+dy, ptb.win_w/4+stim_sz/2+dx, ptb.win_h/4+stim_sz/2+dy];
    
    % check that we're not attempting to draw outside the selected quadrant
    assert(rect(1) >= 0 && rect(2) >= 0 && rect(3) <= ptb.win_w/2 && rect(4) <= ptb.win_h/2);
    
elseif quadrant == 2
    % top right quadrant
    rect = [ptb.win_w/4*3-stim_sz/2+dx, ptb.win_h/4-stim_sz/2+dy, ptb.win_w/4*3+stim_sz/2+dx, ptb.win_h/4+stim_sz/2+dy];
    
    % check that we're not attempting to draw outside the selected quadrant
    assert(rect(1) >= ptb.win_w/2 && rect(2) >= 0 && rect(3) <= ptb.win_w && rect(4) <= ptb.win_h/2);
    
elseif quadrant == 3
    % bottom left quadrant
    rect = [ptb.win_w/4-stim_sz/2+dx, ptb.win_h/4*3-stim_sz/2+dy, ptb.win_w/4+stim_sz/2+dx, ptb.win_h/4*3+stim_sz/2+dy];
    
    % check that we're not attempting to draw outside the selected quadrant
    assert(rect(1) >= 0 && rect(2) >= ptb.win_h/2 && rect(3) <=  ptb.win_w/2 && rect(4) <= ptb.win_h);
    
elseif quadrant == 4
    % bottom right quadrant
    rect = [ptb.win_w/4*3-stim_sz/2+dx, ptb.win_h/4*3-stim_sz/2+dy, ptb.win_w/4*3+stim_sz/2+dx, ptb.win_h/4*3+stim_sz/2+dy];
    
    % check that we're not attempting to draw outside the selected quadrant
    assert(rect(1) >= ptb.win_w/2 && rect(2) >= ptb.win_h/2 && rect(3) <=  ptb.win_w && rect(4) <= ptb.win_h);
    
else
    error('invalid quadrant specification');
end

end