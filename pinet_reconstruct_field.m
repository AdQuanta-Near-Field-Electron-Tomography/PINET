function [Rec_F_x, Rec_F_y, Rec_E_x, Rec_E_y] = pinet_reconstruct_field( ...
    projections, meas_angles, k_x, k_y, x, y, k_elec, params)
%PINET_RECONSTRUCT_FIELD Reconstruct the field from the projection measurements.
% This function contains the core Fourier-space reconstruction.

%% Reconstruction geometry in Fourier space
t = linspace(params.LowerLimit, params.UpperLimit, params.GridSize);

nu = sqrt(k_x.^2 + k_y.^2 - k_elec^2);
theta1 = localWrapTo2Pi(real(atan2(-k_x, k_y) + atan(nu ./ k_elec) - 2 * pi));
theta2 = localWrapTo2Pi(real(atan2(-k_x, k_y) - atan(nu ./ k_elec) - 2 * pi));

meas_dirc = complex(cos(deg2rad(meas_angles)), sin(deg2rad(meas_angles)));
theta1_dirc = complex(cos(theta1), sin(theta1));
theta2_dirc = complex(cos(theta2), sin(theta2));

%% Interpolate the first angular branch between measured projections
[grid_meas, grid_theta] = meshgrid(meas_dirc, theta1_dirc);
angles = angle(grid_meas ./ grid_theta);
[~, theta1_idx_up] = min((angles >= 0) .* abs(angles) + (angles < 0) * realmax, [], 2);
[~, theta1_idx_down] = min((angles <= 0) .* abs(angles) + (angles > 0) * realmax, [], 2);
theta1_idx_up = reshape(theta1_idx_up.', size(theta1));
theta1_idx_down = reshape(theta1_idx_down.', size(theta1));
theta1_up = deg2rad(meas_angles(theta1_idx_up));
theta1_down = deg2rad(meas_angles(theta1_idx_down));
theta1_up = reshape(theta1_up.', size(theta1));
theta1_down = reshape(theta1_down.', size(theta1));

equal_indices = theta1_up == theta1_down;
weight1_up = (cos(0.5 * pi * (theta1_up - theta1) ./ (theta1_up - theta1_down))).^2;
weight1_down = (cos(0.5 * pi * (theta1 - theta1_down) ./ (theta1_up - theta1_down))).^2;
weight1_up(equal_indices) = 0.5;
weight1_down(equal_indices) = 0.5;

%% Interpolate the second angular branch between measured projections
[grid_meas, grid_theta] = meshgrid(meas_dirc, theta2_dirc);
angles = angle(grid_meas ./ grid_theta);
[~, theta2_idx_up] = min((angles >= 0) .* abs(angles) + (angles < 0) * realmax, [], 2);
[~, theta2_idx_down] = min((angles <= 0) .* abs(angles) + (angles > 0) * realmax, [], 2);
theta2_idx_up = reshape(theta2_idx_up.', size(theta2));
theta2_idx_down = reshape(theta2_idx_down.', size(theta2));
theta2_up = deg2rad(meas_angles(theta2_idx_up));
theta2_down = deg2rad(meas_angles(theta2_idx_down));
theta2_up = reshape(theta2_up.', size(theta1));
theta2_down = reshape(theta2_down.', size(theta1));

equal_indices = theta2_up == theta2_down;
weight2_up = (cos(0.5 * pi * (theta2_up - theta2) ./ (theta2_up - theta2_down))).^2;
weight2_down = (cos(0.5 * pi * (theta2 - theta2_down) ./ (theta2_up - theta2_down))).^2;
weight2_up(equal_indices) = 0.5;
weight2_down(equal_indices) = 0.5;

recFxFile = fullfile(params.DataPath, ...
    sprintf('Rec_F_x_grid_%d_dirs_%d.mat', params.GridSize, params.NumOfDirections));
recFyFile = fullfile(params.DataPath, ...
    sprintf('Rec_F_y_grid_%d_dirs_%d.mat', params.GridSize, params.NumOfDirections));

%% Reconstruct the Fourier components of the field
if exist(recFxFile, 'file') && exist(recFyFile, 'file') && ~params.Overwrite
    Rec_F_x = load(recFxFile, 'Rec_F_x').Rec_F_x;
    Rec_F_y = load(recFyFile, 'Rec_F_y').Rec_F_y;
else
    fourier_comp_1 = cell2mat(arrayfun( ...
        @(a, b, c1, d, e1) sum((a * projections(b, :) + c1 * projections(d, :)) .* exp(-1i * e1 * t)), ...
        weight1_up, theta1_idx_up, weight1_down, theta1_idx_down, nu, 'UniformOutput', 0));
    fourier_comp_2 = cell2mat(arrayfun( ...
        @(a, b, c1, d, e1) sum((a * projections(b, :) + c1 * projections(d, :)) .* exp(1i * e1 * t)), ...
        weight2_up, theta2_idx_up, weight2_down, theta2_idx_down, nu, 'UniformOutput', 0));

    Rec_F_x = (-fourier_comp_1 .* cos(theta2) + fourier_comp_2 .* cos(theta1)) ./ sin(theta1 - theta2);
    Rec_F_y = (-fourier_comp_1 .* sin(theta2) + fourier_comp_2 .* sin(theta1)) ./ sin(theta1 - theta2);

    save(recFxFile, 'Rec_F_x');
    save(recFyFile, 'Rec_F_y');
end

%% Keep the physical support and transform back to real space
mask = (k_x.^2 + k_y.^2) > k_elec^2;
Rec_F_x(~mask) = 0;
Rec_F_y(~mask) = 0;

Rec_E_x = fftshift(ifft2(fftshift(Rec_F_x)));
Rec_E_y = fftshift(ifft2(fftshift(Rec_F_y)));
end

function wrapped = localWrapTo2Pi(theta)
wrapped = mod(theta, 2 * pi);
wrapped(wrapped < 0) = wrapped(wrapped < 0) + 2 * pi;
end
