% Copyright 2024 Eelke Spaak, Donders Institute.
% See https://github.com/Spaak/rift-phase-and-visibility for readme/license.
% Belongs with:
% Spaak, E., Bouwkamp, F. G., & de Lange, F. P. (2024). Perceptual foundation and extension
% to phase tagging for rapid invisible frequency tagging (RIFT). Imaging Neuroscience, 2, 1–14.
% https://doi.org/10.1162/imag_a_00242

%% setup stuff

% set this to 1 when doing actual experiment
IS_LIVE = 1;
EYELINK_LIVE = 0;

sca();

% get subject ID from experimenter and make filename based on it
subj_id = input('Please enter a subject ID: ');
sess_id = input('Please enter a session ID: ');
nowtime = clock();
filename = sprintf('results/subj%02d_sess%02d_%04d-%02d-%02dT%02d-%02d-%02d.mat',...
    subj_id, sess_id, nowtime(1:5), round(nowtime(6)));

% setup psychtoolbox and get some parameters about the screen etc.,
% these are used by the presentation subroutines
ptb = InitPsychtoolbox(IS_LIVE);
stim = InitStimuli(ptb);

% initialize bitsibox (to send and receive triggers)
if IS_LIVE
  ptb.btsi = Bitsi('COM1'); % or whichever COM-port used by the PC
  ptb.btsi.validResponses = ['a' 'e']; % index finger button on right (a)/left (e) button boxes
else
  ptb.btsi = Bitsi('');
  ptb.btsi.validResponses = KbName({'a' 'e'});
end

% initialize the eye tracker
if IS_LIVE
  ptb.eye = EyelinkInitDefaults(ptb.win);
  EyelinkInit(~EYELINK_LIVE, 1);

  Eyelink('command', 'link_sample_data = LEFT,RIGHT,GAZE,AREA');
  Eyelink('openfile', sprintf('essub%03d.edf', subj_id));
  EyelinkDoTrackerSetup(ptb.eye);

  WaitSecs(0.1);
  Eyelink('StartRecording');
end

save(filename, 'stim');

%% setup propixx mode

Screen('Flip', ptb.win);

WaitSecs(1);

if IS_LIVE
    Datapixx('Open');
    Datapixx('SetPropixxDlpSequenceProgram', 5); % 2 for 480, 5 for 1440 Hz, 0 for normal
    Datapixx('RegWrRd');
end

%% condition matrix

% nested cell array, each element specifies a block

% passive viewing blocks
blk_pas = {% single stim, four tagging types, fixed phases
           {'single', 60, 1, 0};
           {'single', 60, 2, 0};
           {'single', 60, 3, 0};
           {'single', 60, 4, 0};
           % single stim, tagging type 1 and 4, random phases
           {'single', 60, 1, 1};
           {'single', 60, 4, 1};
           % two stims with tagging
           {'double', [60 66], 1, 1, 0}; % two freqs, type 1, random phases, no phasetag
           {'double', [60 60], 1, 1, 1}; % one freq , type 1, random phases, phasetag
           {'double', [60 66], 4, 1, 0}; % two freqs, type 4, random phases, no phasetag
           {'double', [60 60], 4, 1, 1}; % one freq , type 4, random phases, phasetag
           % stims without tagging ("type 1" for black background)
           {'single', 0, 1, 0};
           {'double', [0 0], 1, 0, 0}
          };

% attentional blocks
blk_att = {
           {'attn', [60 66], 1, 1, 0}; % two freqs, type 1, random phases, no phasetag
           {'attn', [60 60], 1, 1, 1}; % one freq , type 1, random phases, phasetag
          };

% AXB blocks
blk_axb = {
           {'axb', [0 60], 1, 0}; % 60Hz vs no tagging, type 1, no phasetag
           {'axb', [60 66], 1, 0}; % 60Hz vs 66Hz, type 1, no phasetag
           {'axb', [0 60], 4, 0}; % 60Hz vs no tagging, type 4, no phasetag
          };
      
% randomize order of blocks within task type and concatenate
blk_pas = blk_pas(randperm(numel(blk_pas)));
blk_att = blk_att(randperm(numel(blk_att)));
blk_axb = blk_axb(randperm(numel(blk_axb)));

stim.blockspec = [blk_pas; blk_att; blk_axb];
      
%% experiment block loop

nblk = numel(stim.blockspec);

PresentTextAndWait(ptb, stim, sprintf('Thank you for participating in this experiment! The experiment consists of %d blocks. The blocks differ in the exact (simple) task you have to perform. Before each block, please read the brief instructions carefully.\n\nPress a button to view the instructions for the first block.\n\nGood luck and have fun!', nblk), 1);

for blk = 1:nblk
    thisblk = stim.blockspec{blk};
    
    % set background colour depending on tagging type (black for luminance
    % tagging type 1, gray otherwise)
    % do this here rather than in a RunXXXBlock function because this way
    % also the instructions are against the same background colour
    tag_type = thisblk{3};
    if tag_type == 1
        Screen('FillRect', ptb.win, 0);
    else
        Screen('FillRect', ptb.win, 127);
    end
    
    if strcmp(thisblk{1}, 'single')
        PresentTextAndWait(ptb, stim, sprintf('In the next block, you will see one stimulus at a time. Simply keep looking at the dot in the center of the screen and try not to blink.\n\nEvery now and then, the dot will change into a square. When this happens, press a button and blink your eyes.\n\nNext up is block %d of %d. Take a brief break now if you like.', blk, nblk));
        blkfun = @RunSingleStimBlock;
    elseif strcmp(thisblk{1}, 'double')
        PresentTextAndWait(ptb, stim, sprintf('In the next block, you will see two stimuli at a time. Simply keep looking at the dot in the center of the screen and try not to blink.\n\nEvery now and then, the dot will change into a square. When this happens, press a button and blink your eyes.\n\nNext up is block %d of %d. Take a brief break now if you like.', blk, nblk));
        blkfun = @RunTwoStimBlock;
    elseif strcmp(thisblk{1}, 'attn')
        PresentTextAndWait(ptb, stim, sprintf('**NOTE** The next block is an ATTENTIONAL block!\n\nYou will see an arrow to the left or right, followed by two stimuli. Keep looking at the dot in the center of the screen, but pay close attention to the stimulus indicated by the arrow! (So without moving your eyes.)\n\nEvery now and then, the attended stimulus will dim in brightness. When this happens, press a button and blink your eyes.\n\nNext up is block %d of %d. Take a brief break now if you like.', blk, nblk));
        blkfun = @RunAttentionalBlock;
    elseif strcmp(thisblk{1}, 'axb')
        PresentTextAndWait(ptb, stim, sprintf('**NOTE** The next block is a DISCRIMINATION block!\n\nYou will see three stimuli. The middle one is in some way identical to either the leftmost or the rightmost (though you may not be able to see this). After a question mark appears, press the left or right button to indicate which of the two stimuli you think the middle one was identical to. You have 2 seconds to make your response.\n\nDo not worry if this is (very) difficult, just try to make a well-informed guess if you can.\n\nNext up is block %d of %d. Take a brief break now if you like.', blk, nblk));
        blkfun = @RunAXBBlock;
    else
        error('invalid condition specification');
    end
    
    stim.blocks{end+1} = blkfun(ptb, stim, thisblk{2:end});
    save(filename, 'stim');
end

%% finish up

stim.exp_end_time = clock();
stim.btsitriggers = ptb.btsi.triggerLog;
save(filename, 'stim');

PresentTextAndWait(ptb, stim, 'Done! You''re awesome.\n\nPlease remain still for a few more moments while we stop the data acquisition and get you out.');

Screen('CloseAll');

if IS_LIVE
    Datapixx('SetPropixxDlpSequenceProgram', 0); % 2 for 480, 5 for 1440 Hz, 0 for normal
    Datapixx('RegWrRd');
end
