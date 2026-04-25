function out = pinet_run(varargin)
%PINET_RUN Generate the PINET example outputs.

%% Load the package configuration
rootDir = fileparts(mfilename('fullpath'));
cfg = pinet_config(rootDir);

%% Parse user overrides
p = inputParser;
addParameter(p, 'SavePath', cfg.defaults.SavePath, @(x) ischar(x) || isstring(x));
addParameter(p, 'DataPath', cfg.defaults.DataPath, @(x) ischar(x) || isstring(x));
addParameter(p, 'RealVectorSpacingBase', cfg.defaults.RealVectorSpacingBase, @(x) isnumeric(x) && isscalar(x) && x > 0);
addParameter(p, 'ReconstructionVectors', cfg.defaults.ReconstructionVectors, @(x) islogical(x) && isscalar(x));
parse(p, varargin{:});
opts = p.Results;

%% Render the configured output set
out = pinet_render_outputs( ...
    'SavePath', opts.SavePath, ...
    'DataPath', opts.DataPath, ...
    'RealVectorSpacingBase', opts.RealVectorSpacingBase, ...
    'ReconstructionVectors', opts.ReconstructionVectors);
end
