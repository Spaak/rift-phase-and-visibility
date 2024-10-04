%%

all_subs = [1 3 4 5 6 7 8 9 10 11 13 14];

%% geometric preprocessing: use template model and head shape

clear;

subj_id = 14;

% see https://www.fieldtriptoolbox.org/example/fittemplate/

% read headshape and express in mm
filename = sprintf('/project/3018045.03/raw/sub-%03d/ses-meg01/polhemus/sub%03d.pos', subj_id, subj_id);
polhemus = ft_convert_units(ft_read_headshape(filename), 'mm');

if subj_id == 3
  % discard some crazy polhemus points
  inds = polhemus.pos(:,3) > -300;
  polhemus.pos = polhemus.pos(inds,:);
end

% read template and express in mm
% note: need BEM here because that one contains scalp surface (for
% coregistration)
template = ft_read_headmodel('~/repos/fieldtrip/template/headmodel/standard_bem.mat');
template = ft_convert_units(template, 'mm');

% coregistration
% note: could "manually" rotate/scale/translate here already, but guide on
% wiki suggests doing this automatically, see below
cfg = [];
cfg.template.headshape = polhemus;
cfg.template.headmodelstyle = 'surface';
cfg.checksize = inf;
cfg.individual.headmodel = template;
cfg = ft_interactiverealign(cfg);

% store coregistration matrix
transform_template2polhemus_initial = cfg.m;

% for subj 7, found: rotate around Z -90 deg, translate Z 25, translate X
% 20. Should probably scale a bit, but this is done in the step below

%%

% apply the coregistration
template_transformed_initial = ft_transform_geometry(transform_template2polhemus_initial, template);

% fit spheres to scale/translate
cfg             = [];
cfg.method      = 'singlesphere';
sphere_template = ft_prepare_headmodel(cfg, template_transformed_initial.bnd(1));
sphere_polhemus = ft_prepare_headmodel(cfg, polhemus);
scale = sphere_polhemus.r/sphere_template.r;

T1 = [1 0 0 -sphere_template.o(1);
      0 1 0 -sphere_template.o(2);
      0 0 1 -sphere_template.o(3);
      0 0 0 1                ];
S  = [scale 0 0 0;
      0 scale 0 0;
      0 0 scale 0;
      0 0 0 1 ];
T2 = [1 0 0 sphere_polhemus.o(1);
      0 1 0 sphere_polhemus.o(2);
      0 0 1 sphere_polhemus.o(3);
      0 0 0 1                 ];
transformation = T2*S*T1;

% store all transformation in one matrix
transform_template2polhemus = transformation * transform_template2polhemus_initial;

% NOTE: had to comment out error on line 118 about not allowing scaling in
% ft_transform_geometry
template_transformed_end = ft_transform_geometry(transform_template2polhemus, template);

%%

% verify
cfg = [];
cfg.template.headshape = polhemus;
cfg.template.headmodelstyle = 'surface';
cfg.checksize = inf;
cfg.individual.headmodel = template_transformed_end;
cfg_ignored = ft_interactiverealign(cfg);
% looks good! (enough...)

%%

% now prepare single shell headmodel
cfg = [];
cfg.method = 'singleshell';
headmodel_singleshell = ft_prepare_headmodel(cfg, template_transformed_end.bnd(3));

% save
save(sprintf('/project/3018045.03/scratch/sub%03d-headmodel-template-warped.mat', subj_id), 'headmodel_singleshell', 'transform_template2polhemus');

