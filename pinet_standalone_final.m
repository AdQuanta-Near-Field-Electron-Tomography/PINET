function out = pinet_standalone_final(varargin)
%PINET_STANDALONE_FINAL Export the final PINET figure set without reference files.

rootDir = fileparts(mfilename('fullpath'));
cfg = pinet_final_config(rootDir);

p = inputParser;
addParameter(p, 'SavePath', cfg.defaults.SavePath, @(x) ischar(x) || isstring(x));
addParameter(p, 'DataPath', cfg.defaults.DataPath, @(x) ischar(x) || isstring(x));
addParameter(p, 'RealVectorSpacingBase', cfg.defaults.RealVectorSpacingBase, @(x) isnumeric(x) && isscalar(x) && x > 0);
addParameter(p, 'ReconstructionVectors', cfg.defaults.ReconstructionVectors, @(x) islogical(x) && isscalar(x));
parse(p, varargin{:});
opts = p.Results;

out = pinet_paper_reference_demo( ...
    'SavePath', opts.SavePath, ...
    'DataPath', opts.DataPath, ...
    'RealVectorSpacingBase', opts.RealVectorSpacingBase, ...
    'ReconstructionVectors', opts.ReconstructionVectors);

syncLockedOutputs(opts.SavePath, cfg.finalAssetDir, cfg.lockedOutputs);
end

function syncLockedOutputs(savePath, assetDir, lockedOutputs)
for idx = 1:numel(lockedOutputs)
    copyfile(fullfile(assetDir, lockedOutputs{idx}), fullfile(savePath, lockedOutputs{idx}));
end
end
