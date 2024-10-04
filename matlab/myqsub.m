% Copyright 2024 Eelke Spaak, Donders Institute.
% See https://github.com/Spaak/rift-phase-and-visibility for readme/license.
% Belongs with:
% Spaak, E., Bouwkamp, F. G., & de Lange, F. P. (2024). Perceptual foundation and extension
% to phase tagging for rapid invisible frequency tagging (RIFT). Imaging Neuroscience, 2, 1–14.
% https://doi.org/10.1162/imag_a_00242

function myqsub(funname, reqstring, varargin)

% check if we should distribute across as many nodes as possible
if strcmp(varargin{end}, '-spread')
  noquit = 0;
  dospread = 1;
  varargin = varargin(1:end-1);
elseif strcmp(varargin{end}, '-noquit')
  noquit = 1;
  dospread = 0;
  varargin = varargin(1:end-1);
else
  noquit = 0;
  dospread = 0;
end

nargs = numel(varargin);
njob = numel(varargin{1});

matlabcmd = '/opt/matlab/R2021a/bin/matlab -nodesktop -nosplash';

if dospread
  nodes = torque_getnodes();
  goodcpus = [nodes.cputype] > 10;
  goodload = [nodes.ncpu_free] <= median([nodes.ncpu_free]);
  goodnodes = nodes(goodcpus & goodload);
  goodnodeind = 1;
end

% generate a batch identifier, used in naming the log files
batchid = datestr(datetime(), 'yyyy-mm-ddTHH-MM-SS');
mkdir(sprintf('~/.matlabjobs/%s', batchid));

for k = 1:njob
  args = {};
  for l = 1:nargs
    args{l} = num2str(varargin{l}(k));
  end
  args = join(args, ',');
  
  if dospread
    fullreqstring = sprintf('%s,nodes=%s', reqstring, goodnodes(goodnodeind).hostname);
    goodnodeind = goodnodeind+1;
    if goodnodeind > numel(goodnodes)
      goodnodeind = 1;
    end
  else
    fullreqstring = reqstring;
  end
  
  if noquit
    matlabscript = sprintf('cd ~/riftbasics/analysis-4paper/matlab; %s(%s);', funname, args{1});
  else
    matlabscript = sprintf('cd ~/riftbasics/analysis-4paper/matlab; %s(%s); quit', funname, args{1});
  end
  
  % store the output in custom files
  logfile = sprintf('%s/j%s_%s', batchid, args{1}, funname);
  
  qsubcmd = sprintf('qsub -q matlab -l %s -N j%s_%s', fullreqstring, args{1}, funname);
  cmd = sprintf('echo ''stdbuf -oL -eL %s -r "%s" >~/.matlabjobs/%s.out 2>~/.matlabjobs/%s.err'' | %s',...
    matlabcmd, matlabscript, logfile, logfile, qsubcmd);
  
  %fprintf([cmd '\n']);
  [status, result] = system(cmd);
  if status
    error(result);
  end
end

end