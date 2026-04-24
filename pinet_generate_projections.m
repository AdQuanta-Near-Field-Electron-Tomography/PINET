function projections = pinet_generate_projections(E_x, E_y, meas_angles, k_elec, params)
%PINET_GENERATE_PROJECTIONS Generate or reuse cached PINEM projections.

%% The validated projection step depends on imrotate
if ~exist('imrotate', 'file')
    error('pinet_generate_projections:MissingImrotate', ...
        'imrotate is required because the validated projection step depends on it.');
end

%% Reuse cached projections when available
projFile = fullfile(params.DataPath, ...
    sprintf('projections_grid_%d_dirs_%d.mat', params.GridSize, params.NumOfDirections));

if exist(projFile, 'file') && ~params.Overwrite
    tmp = load(projFile, 'projections');
    projections = tmp.projections;
    return;
end

%% Project the field along each measurement angle
projections = zeros(length(meas_angles), params.GridSize);
for alphaInd = 1:size(projections, 1)
    projections(alphaInd, :) = projectField( ...
        E_x, E_y, -meas_angles(alphaInd), k_elec, ...
        params.GridSize, params.UpperLimit, params.LowerLimit);
end

save(projFile, 'projections', 'meas_angles', 'k_elec');
end

function g_calc = projectField(E_x, E_y, alpha_deg, k_elec, GridSize, UpperLimit, LowerLimit)
%PROJECTFIELD Rotate the transverse field and sum along the beam direction.
alpha_rad = deg2rad(alpha_deg);
[~, Y] = meshgrid(linspace(LowerLimit, UpperLimit, GridSize));

E_y_rot = cos(alpha_rad) .* E_y + sin(alpha_rad) .* E_x;
E_y_new = imrotate(E_y_rot, -alpha_deg, 'bilinear', 'crop');
g_calc = sum(E_y_new .* exp(-1i * k_elec * Y));
end
