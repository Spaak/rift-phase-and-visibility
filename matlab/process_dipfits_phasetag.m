% Copyright 2024 Eelke Spaak, Donders Institute.
% See https://github.com/Spaak/rift-phase-and-visibility for readme/license.
% Belongs with:
% Spaak, E., Bouwkamp, F. G., & de Lange, F. P. (2024). Perceptual foundation and extension
% to phase tagging for rapid invisible frequency tagging (RIFT). Imaging Neuroscience, 2, 1–14.
% https://doi.org/10.1162/imag_a_00242

%% load results

% dir for plotting
plotdir = '/home/predatt/eelspa/riftbasics/analysis-4paper/plots';
mkdir(plotdir);

all_subs = [1 3 4 5 6 7 8 9 10 11 13 14];
nsub = numel(all_subs);

% sub X pos X tagtype (1, 4)
pos_peakphase = nan(nsub, 3, 2);
pos_shiftphase = nan(nsub, 3, 2);
peakphase = nan(nsub, 1, 2);
shiftphase = nan(nsub, 1, 2);

alltl_peak = {};
alltl_shift = {};
alldip_peak = {};
alldip_shift = {};

for k = 1:numel(all_subs)
    for l = 1:2
      subj_id = all_subs(k);
      fprintf('loading subject %03d (%d of %d)...\n', subj_id, k, numel(all_subs));

      if l == 1
        res = load(sprintf('/project/3018045.03/scratch/sub%03d-phaseproject-topos-dipfits-alltri.mat', subj_id));
      else
          res = load(sprintf('/project/3018045.03/scratch/sub%03d-phaseproject-topos-dipfits-alltri-tagtype4.mat', subj_id));
      end
      pos_peakphase(k,:,l) = res.pos_peak_mni;
      pos_shiftphase(k,:,l) = res.pos_shift_mni;
      peakphase(k,l) = res.peakph;
      shiftphase(k,l) = res.shiftedph;
      
      alltl_peak{k,l} = res.tl_peak;
      alltl_shift{k,l} = res.tl_shift;
      alldip_peak{k,l} = res.dip_peak;
      alldip_shift{k,l} = res.dip_shift;
    end
end

%% volumetric density both dipole types (peak vs shift)

% average over tagging types
pos_peak_avg = mean(pos_peakphase, 3);
pos_shift_avg = mean(pos_shiftphase, 3);

load('mnibrain.mat');

% note: mri.transform transforms from voxel indices to MNI x/y/z positions
% so pinv(mri.transform) goes from MNI x/y/z to voxel indices

mri_source = ft_checkdata(mri, 'datatype', 'source');
allpos_mni = mri_source.pos;

% estimate density (bandwidth in mm as sd of Gaussian)
bw = 15;
density_peak = mvksdensity(pos_peak_avg, allpos_mni, 'bandwidth', bw);
density_shift = mvksdensity(pos_shift_avg, allpos_mni, 'bandwidth', bw);
density_peak = density_peak ./ max(density_peak);
density_shift = density_shift ./ max(density_shift);
density = density_peak - density_shift;

% (reshape and) add to FT structure
source = mri_source;
source.density = density;
source.mask = abs(density);

% plot volumetric

% attach coordsys to tell FT we can use the atlas (which is also in MNI)
source.coordsys = 'mni';

%% plot

colors = brewermap(2, 'Dark2');
colors = createcolormap(colors(2,:), [1 1 1], colors(1,:));

figure;

cfg = [];
cfg.funparameter = 'density';
cfg.maskparameter = 'mask';
cfg.opacitylim = [0 max(source.mask(:))*0.75];
cfg.funcolormap =  colors;
cfg.location = [0 -82 26];
cfg.method = 'ortho';
cfg.crosshair = 'no';
cfg.atlas = '/home/common/matlab/fieldtrip/template/atlas/aal/ROI_MNI_V4.nii';
ft_sourceplot(cfg, source);

f = gcf();

% remove the coordinate system labels (anterior/posterior) etc. from the
% Maltab figure before saving
delete(findall(f, 'Type', 'text', 'Tag', 'coordsyslabel_x'));
delete(findall(f, 'Type', 'text', 'Tag', 'coordsyslabel_y'));
delete(findall(f, 'Type', 'text', 'Tag', 'coordsyslabel_z'));

exportgraphics(f, sprintf('%s/sourceplots-dipole-density-phasetag.png', plotdir), 'resolution', 300);

f2 = figure('color', 'w');
colormap(colors);
colorbar();
exportgraphics(f2, sprintf('%s/sourceplots-colorbar.pdf', plotdir),...
    'Resolution', 150, 'contenttype', 'vector');

%% save pos and explained variance values for analysis in Python

nsub = size(pos_peakphase,1);
tagtypes = [1 4];

for l = 1:2
  var_explained_peak = nan(nsub, 1);
  var_explained_shift = nan(nsub, 1);
  for k = 1:nsub
    var_explained_peak(k) = corr(alldip_peak{k,l}.Vdata, alldip_peak{k,l}.Vmodel).^2;
    var_explained_shift(k) = corr(alldip_shift{k,l}.Vdata, alldip_shift{k,l}.Vmodel).^2;
  end

  alldat = [pos_peakphase(:,:,l) pos_shiftphase(:,:,l) var_explained_peak var_explained_shift];
  headers = {'xpeak', 'ypeak', 'zpeak', 'xshift', 'yshift', 'zshift', 'r2peak', 'r2shift'};

  T = array2table(alldat, 'VariableNames', headers');
  writetable(T, sprintf('/project/3018045.03/scratch/aggr-dipfits-phase0and90-tagtype%d.csv', tagtypes(l)));

  % also write one with a grouping variable (for use in JASP etc)
  alldat = [[pos_peakphase(:,:,l); pos_shiftphase(:,:,l)] [var_explained_peak; var_explained_shift]];
  alldat = [alldat [zeros(nsub, 1); ones(nsub, 1)]];
  headers = {'x', 'y', 'z', 'r2', 'is_shift'};

  T = array2table(alldat, 'VariableNames', headers');
  writetable(T, sprintf('/project/3018045.03/scratch/aggr-dipfits-phase0and90-tagtype%d-withgroupingvar.csv', tagtypes(l)));
end

