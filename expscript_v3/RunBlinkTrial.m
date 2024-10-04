function RunBlinkTrial(ptb, stim)

ptb.btsi.sendTrigger(stim.trig.TRI_BLINK);

% draw blink stimulus in all four quadrants of buffer
for quadrant = 1:4
    Screen('DrawTexture', ptb.win, stim.tex.blink, [], ...
        MakeOffsetRect(ptb, stim, 0, 0, quadrant));
end

Screen('Flip', ptb.win);

WaitSecs(stim.dur_blink);

end