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