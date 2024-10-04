% Copyright 2024 Eelke Spaak, Donders Institute.
% See https://github.com/Spaak/rift-phase-and-visibility for readme/license.
% Belongs with:
% Spaak, E., Bouwkamp, F. G., & de Lange, F. P. (2024). Perceptual foundation and extension
% to phase tagging for rapid invisible frequency tagging (RIFT). Imaging Neuroscience, 2, 1–14.
% https://doi.org/10.1162/imag_a_00242

function f = fetch_filename(subj_id, file_type)

projdir = '/project/3018045.03/';

datdir = fullfile(projdir, 'raw', sprintf('sub-%03d', subj_id), 'ses-meg01', file_type);

files = dir(datdir);
% exclude . and .. entries
files = files(~ismember({files.name},{'.','..'}));

assert(numel(files)==1);

f = fullfile(datdir, files(1).name);

end