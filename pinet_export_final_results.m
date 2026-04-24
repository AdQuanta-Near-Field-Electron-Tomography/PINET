function out = pinet_export_final_results(varargin)
%PINET_EXPORT_FINAL_RESULTS Export the final approved PINET figure set.

out = pinet_paper_reference_demo(varargin{:});
syncApprovedExports(out.savePath, fileparts(mfilename('fullpath')));
end

function syncApprovedExports(savePath, rootDir)
approvedDir = fullfile(rootDir, 'approved_results_paper_reference_demo');
files = dir(fullfile(approvedDir, '*'));
files = files(~[files.isdir]);

for idx = 1:numel(files)
    copyfile(fullfile(files(idx).folder, files(idx).name), fullfile(savePath, files(idx).name));
end
end
