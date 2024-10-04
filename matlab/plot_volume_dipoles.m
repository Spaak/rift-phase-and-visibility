% Copyright 2024 Eelke Spaak, Donders Institute.
% See https://github.com/Spaak/rift-phase-and-visibility for readme/license.
% Belongs with:
% Spaak, E., Bouwkamp, F. G., & de Lange, F. P. (2024). Perceptual foundation and extension
% to phase tagging for rapid invisible frequency tagging (RIFT). Imaging Neuroscience, 2, 1–14.
% https://doi.org/10.1162/imag_a_00242

function plot_volume_dipoles(dippos, varargin)
% Written by Eelke Spaak, Donders Institute.

mri = ft_getopt(varargin, 'mri');
if isempty(mri)
  load mnibrain.mat;
end

% check if we need to normalize the anatomy contrast values
if max(mri.anatomy(:)) > 1.0
  mri.anatomy = mri.anatomy ./ max(mri.anatomy(:));
end

colors = ft_getopt(varargin, 'colors', repmat('r', [1 size(dippos,1)]));
plotstems = ft_getopt(varargin, 'plotstems', 0);
sphRadius = ft_getopt(varargin, 'sphereradius', 2);
discRadius = ft_getopt(varargin, 'discradius', 1);
discAlpha = ft_getopt(varargin, 'dicalpha', 1);
dipmom = ft_getopt(varargin, 'dipmom', []);
slicepos = ft_getopt(varargin, 'slicepos', [0 0 0]);

% handle colors
if ismatrix(colors) && size(colors, 2) == 3 && size(colors, 1) > 1
   colors = num2cell(colors, 2);
end

if iscell(colors)
  colors = cellfun(@rgb, colors, 'uniformoutput', 0);
else
  colors = arrayfun(@rgb, colors, 'uniformoutput', 0);
end

if numel(colors) == 1
  colors = repmat(colors, 1, size(dippos,1));
end

if numel(sphRadius) == 1
  sphRadius = repmat(sphRadius, 1, size(dippos,1));
end

if numel(discRadius) == 1
  discRadius = repmat(discRadius, 1, size(dippos,1));
end

% compute voxel indices of position at which to take slice images
voxinds = round(ft_warp_apply(pinv(mri.transform), slicepos, 'homogeneous'));

% compute axes in mni space
voxelX = [(1:mri.dim(1))' zeros(mri.dim(1),1) zeros(mri.dim(1),1)];
voxelY = [zeros(mri.dim(2),1) (1:mri.dim(2))' zeros(mri.dim(2),1)];
voxelZ = [zeros(mri.dim(3),1) zeros(mri.dim(3),1) (1:mri.dim(3))'];
mniX = ft_warp_apply(mri.transform, voxelX, 'homogeneous');
mniY = ft_warp_apply(mri.transform, voxelY, 'homogeneous');
mniZ = ft_warp_apply(mri.transform, voxelZ, 'homogeneous');
mniX = mniX(:,1);
mniY = mniY(:,2);
mniZ = mniZ(:,3);

hold on;

cdat = squeeze(mri.anatomy(voxinds(1),:,:))';
cdat = repmat(cdat, [1 1 3]);
surface(...
  [min(mniX) min(mniX); min(mniX) min(mniX)],...
  [min(mniY) max(mniY); min(mniY) max(mniY)],...
  [min(mniZ) min(mniZ); max(mniZ) max(mniZ)],...
  cdat, 'facecolor', 'texturemap','edgecolor', 'none', 'facelighting', 'none');

cdat = squeeze(mri.anatomy(:,voxinds(2),:))';
cdat = repmat(cdat, [1 1 3]);
surface(...
  [min(mniX) max(mniX); min(mniX) max(mniX)],...
  [min(mniY) min(mniY); min(mniY) min(mniY)],...
  [min(mniZ) min(mniZ); max(mniZ) max(mniZ)],...
  cdat, 'facecolor', 'texturemap','edgecolor', 'none', 'facelighting', 'none');

cdat = squeeze(mri.anatomy(:,:,voxinds(3)))';
cdat = repmat(cdat, [1 1 3]);
surface(...
  [min(mniX) max(mniX); min(mniX) max(mniX)],...
  [min(mniY) min(mniY); max(mniY) max(mniY)],...
  [min(mniZ) min(mniZ); min(mniZ) min(mniZ)],...
  cdat, 'facecolor', 'texturemap','edgecolor', 'none', 'facelighting', 'none');

xlabel('MNI x (mm)');
ylabel('MNI y (mm)');
zlabel('MNI z (mm)');

% now plot dipoles as spheres
[sphX sphY sphZ] = sphere(20);

for k = 1:size(dippos,1)
  pos = dippos(k,:);
  
  thissphX = sphX.*sphRadius(k);
  thissphY = sphY.*sphRadius(k);
  thissphZ = sphZ.*sphRadius(k);
  
  % create color data for this sphere
  sphColor = repmat(permute(colors{k}, [3 1 2]), [size(thissphZ) 1]);
  discColor = sphColor;

  if isempty(dipmom)
      mom = [0 0 0];
  else
      mom = dipmom(k,:);
  end
  
  ft_plot_dipole(pos, mom, 'diameter', 2*sphRadius(k), 'unit', 'mm',...
      'color', colors{k});
  
%    surf(sphX+pos(1),sphY+pos(2),sphZ+pos(3),...
%      sphColor, 'facelighting', 'phong', 'facecolor', 'interp', 'edgecolor', 'none');
  
  % stems from the dipole spheres to the MRI faces
  if plotstems
    plot3([pos(1) min(mniX)], [pos(2) pos(2)], [pos(3) pos(3)], 'k--', 'color', [colors{k} 0.5]);
    plot3([pos(1) pos(1)], [pos(2) min(mniY)], [pos(3) pos(3)], 'k--', 'color', [colors{k} 0.5]);
    plot3([pos(1) pos(1)], [pos(2) pos(2)], [pos(3) min(mniZ)], 'k--', 'color', [colors{k} 0.5]);
  end

  h = surf(thissphX./sphRadius(k).*discRadius(k)+pos(1),thissphY./sphRadius(k).*discRadius(k)+pos(2),repmat(min(mniZ)+0.5,size(thissphZ)),...
    discColor, 'facelighting', 'none', 'facecolor', 'texturemap', 'edgecolor', 'none');
  alpha(h, discAlpha);
  
  h = surf(repmat(min(mniX)+0.5,size(thissphX)),thissphY./sphRadius(k).*discRadius(k)+pos(2),thissphZ./sphRadius(k).*discRadius(k)+pos(3),...
    discColor, 'facelighting', 'none', 'facecolor', 'texturemap', 'edgecolor', 'none');
  alpha(h, discAlpha);
  
  h = surf(thissphX./sphRadius(k).*discRadius(k)+pos(1),repmat(min(mniY)+0.5,size(thissphY)),thissphZ./sphRadius(k).*discRadius(k)+pos(3),...
    discColor, 'facelighting', 'none', 'facecolor', 'texturemap', 'edgecolor', 'none');
  alpha(h, discAlpha);

end

camlight;
view(131, 28);

set(gca, 'gridlinestyle', '-');
grid on;
%axis image;

end