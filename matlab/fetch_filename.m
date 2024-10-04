function f = fetch_filename(subj_id, file_type)

projdir = '/project/3018045.03/';

datdir = fullfile(projdir, 'raw', sprintf('sub-%03d', subj_id), 'ses-meg01', file_type);

files = dir(datdir);
% exclude . and .. entries
files = files(~ismember({files.name},{'.','..'}));

assert(numel(files)==1);

f = fullfile(datdir, files(1).name);

end