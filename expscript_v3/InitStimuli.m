function stim = InitStimuli(ptb)

stim = [];

stim.exp_start_time = clock();

stim.rand_seed = now();
rng(stim.rand_seed);

% time interval between physical frames (actual presentation rate of
% projector)
stim.dt = 1/1440;

% parameters for converting back and forth between pixels and degrees of
% visual angle
stim.screen_w = 48;%53;%38;     % cm (38 2nd screen at desk; 53 in cubicle or home desk; 48 in meg)
stim.view_dist = 85;%61;%70;    % cm (70 2nd screen at desk; 61 in cubicle or home desk (approx); 85 in meg)
stim.pixel_size = stim.screen_w / ptb.win_w * 2; % note: *2 factor because of ProPIXX tagging
stim.pix2deg = @(px) (360./pi .* atan(px.*stim.pixel_size./(2.*stim.view_dist)));
stim.deg2pix = @(deg) (2.*stim.view_dist.*tan(pi./360.*deg)./stim.pixel_size);


% grating patch parameters
stim.param.grating_size = 4; % radius of grating (vis. deg)
stim.param.grating_margin = 0.2; % extra margin around grating to ensure nice round edge (vis. deg)
stim.param.grating_center_cutout = 0.4; % radius of cutout in center of grating
stim.param.grating_ang = [-45 45]; % degrees
stim.param.grating_exc = 5; % excentricity (offset; distance between screen center and grating center on 2/4 stim trials), vis. deg

stim.param.grating_axb_exc = 3;

% grating cycle length should be even number of *pixels*, so that we get
% equally wide black and white bands
% choose this number such that the actual spatial frequency is as close to
% 2 as possible
stim.param.grating_freq_desired = 1.8;
stim.param.grating_period_px = round(stim.deg2pix(1/stim.param.grating_freq_desired)/2)*2;
stim.param.grating_freq = 1/stim.pix2deg(stim.param.grating_period_px);

% create grating patch at 0 degrees rotation (rotation will be done in
% drawing)
% use square wave for now to maximize local contrast
total_radius = stim.param.grating_size+stim.param.grating_margin;
siz_px = round(stim.deg2pix(total_radius*2));

grating_sig = make_square_wave(siz_px, stim.param.grating_period_px)';

% make the circular aperture at four times the size and downscale for a properly
% anti-aliased edge
xbig = (1:1/4:siz_px)/siz_px*total_radius*2 - total_radius;
grating_win = sqrt(xbig.^2 + (xbig').^2) < stim.param.grating_size;

% cut out a hole in the center
grating_win = grating_win & sqrt(xbig.^2 + (xbig').^2) > stim.param.grating_center_cutout;

grating_win = imresize(double(grating_win), [siz_px siz_px], 'bicubic');
grating_win(grating_win<0) = 0;
grating_win(grating_win>1) = 1;
grating_img = uint8(ones(siz_px, siz_px) .* grating_sig .* 255);
grating_img(:,:,2) = grating_win .* 255;
stim.grating = grating_img;
stim.tex.grating = Screen('MakeTexture', ptb.win, grating_img);


% smaller grating for use in AXB trials
buf = Screen('OpenOffscreenWindow', ptb.win, [0 0 0 0], [0 0 siz_px siz_px], [], [], 4);
rect = [siz_px/4, siz_px/4, siz_px/4+siz_px/2, siz_px/4+siz_px/2];
Screen('DrawTexture', buf, stim.tex.grating, [], rect);
stim.tex.grating_small = Screen('OpenOffscreenWindow', ptb.win, [0 0 0 0], [0 0 siz_px siz_px]);
Screen('CopyWindow', buf, stim.tex.grating_small);


% create luminance disc texture
lum_img = ones(siz_px, siz_px, 'uint8') * 255;
lum_img(:,:,2) = grating_win .* 255;
stim.lum_disc = lum_img;
stim.tex.lum_disc = Screen('MakeTexture', ptb.win, lum_img);

% also store fixation dot as texture (easier drawing/translation later)
stim.param.fix_rad_outer = 0.2;
stim.param.fix_rad_inner = 0.1;
% draw the fixation dot into an anti-aliased buffer first, then copy into
% regular window (necessary to get anti-aliasing)
buf = Screen('OpenOffscreenWindow', ptb.win, [0 0 0 0], [0 0 siz_px siz_px], [], [], 4);
rect = [siz_px/2-stim.deg2pix(stim.param.fix_rad_outer), siz_px/2-stim.deg2pix(stim.param.fix_rad_outer), siz_px/2+stim.deg2pix(stim.param.fix_rad_outer), siz_px/2+stim.deg2pix(stim.param.fix_rad_outer)];
Screen('FillOval', buf, 255, rect);
rect = [siz_px/2-stim.deg2pix(stim.param.fix_rad_inner), siz_px/2-stim.deg2pix(stim.param.fix_rad_inner), siz_px/2+stim.deg2pix(stim.param.fix_rad_inner), siz_px/2+stim.deg2pix(stim.param.fix_rad_inner)];
Screen('FillOval', buf, 0, rect);
stim.tex.fix = Screen('OpenOffscreenWindow', ptb.win, [0 0 0 0], [0 0 siz_px siz_px]);
Screen('CopyWindow', buf, stim.tex.fix);


% arrow stims (1 - left pointing arrow; 2 - right pointing arrow)
stim.param.arrow_siz = 1;
stim_px = stim.deg2pix(stim.param.arrow_siz);
buf = Screen('OpenOffscreenWindow', ptb.win, [0 0 0 0], [0 0 siz_px siz_px], [], [], 4);
points = [siz_px/2-stim_px/2, siz_px/2;
          siz_px/2+stim_px/2, siz_px/2+stim_px/2;
          siz_px/2+stim_px/2, siz_px/2-stim_px/2];
Screen('FillPoly', buf, 255, points);
stim.tex.arrows(1) = Screen('OpenOffscreenWindow', ptb.win, [0 0 0 0], [0 0 siz_px siz_px]);
Screen('CopyWindow', buf, stim.tex.arrows(1));

buf = Screen('OpenOffscreenWindow', ptb.win, [0 0 0 0], [0 0 siz_px siz_px], [], [], 4);
points = [siz_px/2+stim_px/2, siz_px/2;
          siz_px/2-stim_px/2, siz_px/2+stim_px/2;
          siz_px/2-stim_px/2, siz_px/2-stim_px/2];
Screen('FillPoly', buf, 255, points);
stim.tex.arrows(2) = Screen('OpenOffscreenWindow', ptb.win, [0 0 0 0], [0 0 siz_px siz_px]);
Screen('CopyWindow', buf, stim.tex.arrows(2));


% eye blink/button press stimulus (outlined square)
stim.param.blink_rad = 1;
buf = Screen('OpenOffscreenWindow', ptb.win, [0 0 0 0], [0 0 siz_px siz_px], [], [], 4);
rect = [siz_px/2-stim.deg2pix(stim.param.blink_rad), siz_px/2-stim.deg2pix(stim.param.blink_rad), siz_px/2+stim.deg2pix(stim.param.blink_rad), siz_px/2+stim.deg2pix(stim.param.blink_rad)];
Screen('FrameRect', buf, 255, rect, 4);
stim.tex.blink = Screen('OpenOffscreenWindow', ptb.win, [0 0 0 0], [0 0 siz_px siz_px]);
Screen('CopyWindow', buf, stim.tex.blink);


% diode tracking square
stim.param.diode_track_size = 1; % vis deg
sz = round(stim.deg2pix(stim.param.diode_track_size));
stim.tex.diode_track = Screen('OpenOffscreenWindow', ptb.win, [0 0 0 0], [0 0 siz_px siz_px]);
Screen('FillRect', stim.tex.diode_track, 255, [0 siz_px-sz sz siz_px]);


% question mark while waiting for response
stim.tex.question = Screen('OpenOffscreenWindow', ptb.win, [0 0 0 0], [0 0 siz_px siz_px]);
Screen('TextFont', stim.tex.question, 'Calibri');
Screen('TextSize', stim.tex.question, 26);
Screen('TextStyle', stim.tex.question, 1);
DrawFormattedText(stim.tex.question, '?', 'center', 'center', 255);


% timing parameters
stim.dur_bsl_min = 0.5; % s
stim.dur_bsl_max = 0.8; % s
stim.dur_stim_passive = 1.2; % s
stim.dur_stim_axb = 1.5; % s
stim.dur_resp_axb = 2.0; % s
stim.dur_blink = 2.5; % s
stim.dur_attcue = 0.5; % s


% contrast change parameters for attentional blocks
stim.tim_change_min = 0.3; % s
stim.tim_change_max = 1.0; % s
stim.prob_change = 0.10;
stim.contrast_dim = 0.15;


% make sure that all durations of tagged stimuli are integer multiples of
% 12 (i.e. the number of physical frames in one framebuffer flip)
% (note that simple modulus mod() gives weird results due to numeric
% roundoffs)
assert(abs(round(stim.dur_stim_passive/stim.dt/12) - stim.dur_stim_passive/stim.dt/12) < stim.dt/10);
assert(abs(round(stim.dur_stim_axb/stim.dt/12) - stim.dur_stim_axb/stim.dt/12) < stim.dt/10);


% numbers of trials etc
stim.numtri_block_single = 50;
stim.numtri_block_two = 80;
stim.numtri_block_attentional = 100;
stim.numtri_block_axb = 50;


% used to store block-specific stimulus parameters
stim.blocks = {};


% define triggers
% rest of triggers is created by MakeOnsetTrig
stim.trig.TRI_BLINK = 255;

stim.trig.TRI_AXB_PHASES = 240;
stim.trig.TRI_AXB_TAGNOTAG = 241;
stim.trig.TRI_AXB_FREQS = 242;


end