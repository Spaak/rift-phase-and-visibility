function diode_rects = MakeDiodeRects(ptb, stim)

diode_rects = zeros(4, 4);
stim_sz = size(stim.grating, 1);
for quadrant = 1:4
    diode_rects(quadrant,:) = MakeOffsetRect(ptb, stim,...
        -ptb.win_w/4+stim_sz/2, ptb.win_h/4-stim_sz/2, quadrant);
end

end