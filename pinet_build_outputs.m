function summary = pinet_build_outputs(varargin)
%PINET_BUILD_OUTPUTS Generate the configured PINET figures.

%% Parse build options
rootDir = fileparts(mfilename('fullpath'));

p = inputParser;
addParameter(p, 'FigureSpec', struct([]), @(x) isstruct(x) || isempty(x));
addParameter(p, 'SavePath', fullfile(rootDir, 'results_pinet_build'), @(x) ischar(x) || isstring(x));
addParameter(p, 'DataPath', fullfile(rootDir, 'data_pinet_build'), @(x) ischar(x) || isstring(x));
addParameter(p, 'MeasurementAngles', linspace(0, 360, 17), @(x) isnumeric(x) && isvector(x) && ~isempty(x));
addParameter(p, 'WaveLength', 700e-9, @(x) isnumeric(x) && isscalar(x) && x > 0);
addParameter(p, 'WireRadiusFactor', 0.1, @(x) isnumeric(x) && isscalar(x) && x > 0);
addParameter(p, 'WindowFactor', 0.25, @(x) isnumeric(x) && isscalar(x) && x > 0);
addParameter(p, 'FourierWindowFactor', 5, @(x) isnumeric(x) && isscalar(x) && x > 0);
addParameter(p, 'FigureWindowFactor', 5, @(x) isnumeric(x) && isscalar(x) && x > 0);
addParameter(p, 'GridStyle', 'combined', @(x) ischar(x) || isstring(x));
addParameter(p, 'FigureGridStyle', 'legacy', @(x) ischar(x) || isstring(x));
addParameter(p, 'FigureFieldVariant', 'static', @(x) ischar(x) || isstring(x));
addParameter(p, 'HPFFactor', 1, @(x) isnumeric(x) && isscalar(x) && x > 0);
addParameter(p, 'UseVectorFields', false, @(x) islogical(x) && isscalar(x));
addParameter(p, 'FourierZoomFactor', 9, @(x) isnumeric(x) && isscalar(x) && x >= 1);
addParameter(p, 'RealSpaceZoomFactor', 25, @(x) isnumeric(x) && isscalar(x) && x >= 1);
addParameter(p, 'FourierUseLog', false, @(x) islogical(x) && isscalar(x));
addParameter(p, 'FourierVectors', true, @(x) islogical(x) && isscalar(x));
addParameter(p, 'RealVectorSpacingBase', 500, @(x) isnumeric(x) && isscalar(x) && x > 0);
addParameter(p, 'FourierVectorSpacingBase', 25, @(x) isnumeric(x) && isscalar(x) && x > 0);
addParameter(p, 'GaussianSigma', 2, @(x) isnumeric(x) && isscalar(x) && x >= 0);
addParameter(p, 'MedianFactor', 0.25, @(x) isnumeric(x) && isscalar(x) && x > 0);
addParameter(p, 'PeronaIterations', 10, @(x) isnumeric(x) && isscalar(x) && x >= 0);
addParameter(p, 'PeronaK', 2.0e5, @(x) isnumeric(x) && isscalar(x) && x > 0);
addParameter(p, 'PeronaDeltaT', 0.2, @(x) isnumeric(x) && isscalar(x) && x > 0);
addParameter(p, 'FigureNames', strings(0, 1), @(x) isstring(x) || iscellstr(x) || ischar(x));
parse(p, varargin{:});
opts = p.Results;

%% Prepare output folders and figure specification
ensureDir(opts.SavePath);
ensureDir(opts.DataPath);

cm = loadDefaultColormap(rootDir);
spec = opts.FigureSpec;

requestedNames = string(opts.FigureNames);
requestedNames = requestedNames(:);
if ~isempty(requestedNames) && ~(numel(requestedNames) == 1 && strlength(requestedNames) == 0)
    keepMask = ismember(string({spec.Name}), requestedNames.');
    spec = spec(keepMask);
end

%% Precompute each grid size once
gridSizes = unique([spec.GridSize]);
gridResults = containers.Map('KeyType', 'double', 'ValueType', 'any');
figureGridResults = containers.Map('KeyType', 'double', 'ValueType', 'any');
fourierGridResults = containers.Map('KeyType', 'double', 'ValueType', 'any');

for idx = 1:numel(gridSizes)
    gridSize = gridSizes(idx);
    gridSpec = spec([spec.GridSize] == gridSize);
    kindsNeeded = string({gridSpec.Kind});
    gridResults(gridSize) = runGridCase(gridSize, opts, cm, kindsNeeded, false);
    if any(ismember(kindsNeeded, ["simulated_real", "fourier_real", "hpf_c_fourier", "hpf_c_real", "hpf_v_fourier", "hpf_v_real"]))
        figureGridResults(gridSize) = runGridCase(gridSize, opts, cm, kindsNeeded, true);
        fourierGridResults(gridSize) = figureGridResults(gridSize);
    end
end

summary = struct();
summary.specPath = "";
summary.savePath = string(opts.SavePath);
summary.generated = strings(0, 1);

%% Export the requested figures
for idx = 1:numel(spec)
    item = spec(idx);
    results = gridResults(item.GridSize);

    switch item.Kind
        case "simulated_real"
            results = gridResults(item.GridSize);
            exportFieldFigure(results.grid.x, results.grid.y, results.E_x, results.E_y, item.Name, opts.SavePath, cm, item.Width, item.Height, item.GridSize, opts.UseVectorFields, opts.RealSpaceZoomFactor, opts.RealVectorSpacingBase);
        case "fourier_real"
            results = fourierGridResults(item.GridSize);
            exportZoomedFourierFigure(results.k.x, results.k.y, results.F_x, results.F_y, item.Name, opts.SavePath, item.Width, item.Height, item.GridSize, opts.FourierZoomFactor, opts.FourierUseLog, opts.FourierVectors, opts.FourierVectorSpacingBase);
        case "hpf_c_fourier"
            results = fourierGridResults(item.GridSize);
            exportZoomedFourierFigure(results.k.x, results.k.y, results.F_x_HPF_c, results.F_y_HPF_c, item.Name, opts.SavePath, item.Width, item.Height, item.GridSize, opts.FourierZoomFactor, opts.FourierUseLog, opts.FourierVectors, opts.FourierVectorSpacingBase);
        case "hpf_c_real"
            results = gridResults(item.GridSize);
            exportFieldFigure(results.grid.x, results.grid.y, results.E_x_HPF_c, results.E_y_HPF_c, item.Name, opts.SavePath, cm, item.Width, item.Height, item.GridSize, opts.UseVectorFields, opts.RealSpaceZoomFactor, opts.RealVectorSpacingBase);
        case "hpf_v_fourier"
            results = fourierGridResults(item.GridSize);
            exportZoomedFourierFigure(results.k.x, results.k.y, results.F_x_HPF_v, results.F_y_HPF_v, item.Name, opts.SavePath, item.Width, item.Height, item.GridSize, opts.FourierZoomFactor, opts.FourierUseLog, opts.FourierVectors, opts.FourierVectorSpacingBase);
        case "hpf_v_real"
            results = gridResults(item.GridSize);
            exportFieldFigure(results.grid.x, results.grid.y, results.E_x_HPF_v, results.E_y_HPF_v, item.Name, opts.SavePath, cm, item.Width, item.Height, item.GridSize, opts.UseVectorFields, opts.RealSpaceZoomFactor, opts.RealVectorSpacingBase);
        case "blurred_rec"
            exportReconstructionFigure(results.grid.x, results.grid.y, results.Rec_E_x_blur, results.Rec_E_y_blur, item.Name, opts.SavePath, cm, item.Width, item.Height, item.GridSize, opts.UseVectorFields, opts.RealVectorSpacingBase);
        case "median_rec"
            exportReconstructionFigure(results.grid.x, results.grid.y, results.Rec_E_x_med, results.Rec_E_y_med, item.Name, opts.SavePath, cm, item.Width, item.Height, item.GridSize, opts.UseVectorFields, opts.RealVectorSpacingBase);
        case "pm_rec"
            exportReconstructionFigure(results.grid.x, results.grid.y, results.pm_Rec_E_x, results.pm_Rec_E_y, item.Name, opts.SavePath, cm, item.Width, item.Height, item.GridSize, opts.UseVectorFields, opts.RealVectorSpacingBase);
    end

    summary.generated(end + 1, 1) = string(item.Name);
end

disp(opts.SavePath);
end

function results = runGridCase(gridSize, opts, cm, kindsNeeded, useFigureSession)
%% Build one simulation case
if nargin < 5
    useFigureSession = false;
end

params = struct();
params.SavePath = opts.SavePath;
if useFigureSession
    params.DataPath = fullfile(opts.DataPath, sprintf('grid_%d_figure_session', gridSize));
else
    params.DataPath = fullfile(opts.DataPath, sprintf('grid_%d', gridSize));
end
params.Overwrite = true;
params.ElectronEnergyKeV = 200;
params.RestEnergyKeV = 511.0;
params.WaveLength = opts.WaveLength;
params.Epsilon1 = -16.49 + 1.06i;
params.Epsilon2 = 1;
params.E0 = 1e6;
params.WireRadius = opts.WireRadiusFactor * opts.WaveLength;
params.GridSize = gridSize;
if useFigureSession
    params.UpperLimit = opts.FigureWindowFactor * opts.WaveLength;
    params.LowerLimit = -opts.FigureWindowFactor * opts.WaveLength;
else
    params.UpperLimit = opts.WindowFactor * opts.WaveLength;
    params.LowerLimit = -opts.WindowFactor * opts.WaveLength;
end
params.NumOfDirections = numel(opts.MeasurementAngles) - 1;
params.GaussianSigma = opts.GaussianSigma;
params.MedianFactor = opts.MedianFactor;
params.PeronaIterations = opts.PeronaIterations;
params.PeronaK = opts.PeronaK;
params.PeronaDeltaT = opts.PeronaDeltaT;
params.Colormap = cm;
if useFigureSession
    params.GridStyle = char(opts.FigureGridStyle);
    params.FieldVariant = char(opts.FigureFieldVariant);
else
    params.GridStyle = char(opts.GridStyle);
    params.FieldVariant = 'phase';
end
params.HPFFactor = opts.HPFFactor;

ensureDir(params.DataPath);

%% Simulate the field on the real-space and Fourier grids
[x, y, k_x, k_y] = buildSimulationGrids(params);
[E_x, E_y, k_elec, k_free] = pinet_simulate_wire_field(x, y, params);
E_x_fourier = E_x;
E_y_fourier = E_y;
if useFigureSession && strcmpi(params.FieldVariant, 'static')
    E_x_fourier = E_x + params.E0;
end

if strcmpi(params.GridStyle, 'cleo3')
    F_x = fftshift(fft2(E_x_fourier));
    F_y = fftshift(fft2(E_y_fourier));
else
    F_x = fftshift(fft2(fftshift(E_x_fourier)));
    F_y = fftshift(fft2(fftshift(E_y_fourier)));
end

%% Apply the high-pass filters used in the exported figures
F_x_HPF_c = F_x;
F_y_HPF_c = F_y;
mask_HPF_c = (k_x.^2 + k_y.^2) <= (params.HPFFactor * k_free)^2;
F_x_HPF_c(mask_HPF_c) = 0;
F_y_HPF_c(mask_HPF_c) = 0;
E_x_HPF_c = fftshift(ifft2(fftshift(F_x_HPF_c)));
E_y_HPF_c = fftshift(ifft2(fftshift(F_y_HPF_c))); %#ok<NASGU>

F_x_HPF_v = F_x;
F_y_HPF_v = F_y;
mask_HPF_v = (k_x.^2 + k_y.^2) <= (params.HPFFactor * k_elec)^2;
F_x_HPF_v(mask_HPF_v) = 0;
F_y_HPF_v(mask_HPF_v) = 0;
E_x_HPF_v = fftshift(ifft2(fftshift(F_x_HPF_v)));
E_y_HPF_v = fftshift(ifft2(fftshift(F_y_HPF_v))); %#ok<NASGU>

%% Reconstruction pipeline: projections -> Fourier reconstruction -> filtered images
needReconstruction = any(ismember(kindsNeeded, ["blurred_rec", "median_rec", "pm_rec"]));
if needReconstruction
    projections = pinet_generate_projections(E_x, E_y, opts.MeasurementAngles, k_elec, params);
    % This is the main reconstruction step.
    [Rec_F_x, Rec_F_y, Rec_E_x, Rec_E_y] = pinet_reconstruct_field( ...
        projections, opts.MeasurementAngles, k_x, k_y, x, y, k_elec, params);
    [Rec_E_x_blur, Rec_E_y_blur, Rec_E_x_med, Rec_E_y_med, pm_Rec_E_x, pm_Rec_E_y] = postprocessCombined(Rec_E_x, Rec_E_y, params);
else
    Rec_F_x = [];
    Rec_F_y = [];
    Rec_E_x = [];
    Rec_E_y = [];
    Rec_E_x_blur = [];
    Rec_E_y_blur = [];
    Rec_E_x_med = [];
    Rec_E_y_med = [];
    pm_Rec_E_x = [];
    pm_Rec_E_y = [];
end

results = struct();
results.grid = struct('x', x, 'y', y);
results.k = struct('x', k_x, 'y', k_y, 'elec', k_elec, 'free', k_free);
results.E_x = E_x;
results.E_y = E_y;
results.F_x = F_x;
results.F_y = F_y;
results.F_x_HPF_c = F_x_HPF_c;
results.F_y_HPF_c = F_y_HPF_c;
results.E_x_HPF_c = E_x_HPF_c;
results.E_y_HPF_c = E_y_HPF_c;
results.F_x_HPF_v = F_x_HPF_v;
results.F_y_HPF_v = F_y_HPF_v;
results.E_x_HPF_v = E_x_HPF_v;
results.E_y_HPF_v = E_y_HPF_v;
results.Rec_F_x = Rec_F_x;
results.Rec_F_y = Rec_F_y;
results.Rec_E_x = Rec_E_x;
results.Rec_E_y = Rec_E_y;
results.Rec_E_x_blur = Rec_E_x_blur;
results.Rec_E_y_blur = Rec_E_y_blur;
results.Rec_E_x_med = Rec_E_x_med;
results.Rec_E_y_med = Rec_E_y_med;
results.pm_Rec_E_x = pm_Rec_E_x;
results.pm_Rec_E_y = pm_Rec_E_y;
end

function [x, y, k_x, k_y] = buildSimulationGrids(params)
%% Build the spatial and Fourier sampling grids
if strcmpi(params.GridStyle, 'legacy') || strcmpi(params.GridStyle, 'cleo3')
    [x, y] = meshgrid(linspace(params.LowerLimit, params.UpperLimit, params.GridSize));
    [k_x, k_y] = meshgrid( ...
        linspace(-2 * pi * params.GridSize / (2 * (params.UpperLimit - params.LowerLimit)), ...
                 2 * pi * params.GridSize / (2 * (params.UpperLimit - params.LowerLimit)), ...
                 params.GridSize));
    return;
end

gridSize = params.GridSize;
upperLimit = params.UpperLimit;
lowerLimit = params.LowerLimit;

[x, y] = meshgrid( ...
    linspace(lowerLimit - (upperLimit - lowerLimit) / (2 * gridSize), ...
             upperLimit - (upperLimit - lowerLimit) / (2 * gridSize), ...
             gridSize));
[k_x, k_y] = meshgrid( ...
    linspace(-2 * pi * (gridSize + 1) / (2 * (upperLimit - lowerLimit)), ...
             2 * pi * (gridSize - 1) / (2 * (upperLimit - lowerLimit)), ...
              gridSize));
end

function [Rec_E_x_blur, Rec_E_y_blur, Rec_E_x_med, Rec_E_y_med, pm_Rec_E_x, pm_Rec_E_y] = postprocessCombined(Rec_E_x, Rec_E_y, params)
%% Post-process the reconstructed field
if params.GaussianSigma > 0 && exist('imgaussfilt', 'file')
    Rec_E_x_blur = complex(imgaussfilt(real(Rec_E_x), params.GaussianSigma), imgaussfilt(imag(Rec_E_x), params.GaussianSigma));
    Rec_E_y_blur = complex(imgaussfilt(real(Rec_E_y), params.GaussianSigma), imgaussfilt(imag(Rec_E_y), params.GaussianSigma));
else
    Rec_E_x_blur = Rec_E_x;
    Rec_E_y_blur = Rec_E_y;
end

if exist('medfilt2', 'file')
    medFilterSize = max(1, floor(params.MedianFactor * params.GridSize^0.8));
    Rec_E_x_med = complex( ...
        medfilt2(real(Rec_E_x_blur), [medFilterSize, medFilterSize]), ...
        medfilt2(imag(Rec_E_x_blur), [medFilterSize, medFilterSize]));
    Rec_E_y_med = complex( ...
        medfilt2(real(Rec_E_y_blur), [medFilterSize, medFilterSize]), ...
        medfilt2(imag(Rec_E_y_blur), [medFilterSize, medFilterSize]));
else
    Rec_E_x_med = Rec_E_x_blur;
    Rec_E_y_med = Rec_E_y_blur;
end

pm_Rec_E_x = peronaMalikDiffusion(Rec_E_x_med, params.PeronaIterations, params.PeronaK, params.PeronaDeltaT);
pm_Rec_E_y = peronaMalikDiffusion(Rec_E_y_med, params.PeronaIterations, params.PeronaK, params.PeronaDeltaT);
end

function diffusedImage = peronaMalikDiffusion(image, numIterations, k, delta_t)
%% Diffuse the real and imaginary parts separately
realPart = peronaMalikReal(real(image), numIterations, k, delta_t);
imagPart = peronaMalikReal(imag(image), numIterations, k, delta_t);
diffusedImage = complex(realPart, imagPart);
end

function diffusedImage = peronaMalikReal(image, numIterations, k, delta_t)
diffusedImage = double(image);

for iter = 1:numIterations
    north = zeros(size(diffusedImage));
    south = zeros(size(diffusedImage));
    east = zeros(size(diffusedImage));
    west = zeros(size(diffusedImage));

    north(2:end, :) = diffusedImage(1:end-1, :) - diffusedImage(2:end, :);
    south(1:end-1, :) = diffusedImage(2:end, :) - diffusedImage(1:end-1, :);
    east(:, 1:end-1) = diffusedImage(:, 2:end) - diffusedImage(:, 1:end-1);
    west(:, 2:end) = diffusedImage(:, 1:end-1) - diffusedImage(:, 2:end);

    cN = exp(-(abs(north) / k).^2);
    cS = exp(-(abs(south) / k).^2);
    cE = exp(-(abs(east) / k).^2);
    cW = exp(-(abs(west) / k).^2);

    diffusedImage = diffusedImage + delta_t * (cN .* north + cS .* south + cE .* east + cW .* west);
end
end

function exportHeatFigure(X, Y, V, name, savePath, cm, figWidth, figHeight)
svgScale = 1 / 1.25;
fig = figure('Visible', 'off', 'Color', 'w', 'Units', 'pixels', ...
    'Position', [100 100 round(figWidth * svgScale) round(figHeight * svgScale)]);
imagesc(X(1, :), Y(:, 1), real(V));
axis equal tight;
set(gca, 'YDir', 'normal');
colorbar;
colormap(cm);
title(name, 'Interpreter', 'none');
xlabel('x [m]');
ylabel('y [m]');
set(gca, 'FontSize', chooseFontSize(figWidth));

climVal = prctile(abs(real(V(:))), 95);
if climVal > 0
    clim([-1, 1] * climVal);
end

writeSvgPng(fig, fullfile(savePath, name));
close(fig);
end

function exportFieldFigure(X, Y, Vx, Vy, name, savePath, cm, figWidth, figHeight, ~, useVectorFields, realSpaceZoomFactor, realVectorSpacingBase)
if ~useVectorFields
    exportHeatFigure(X, Y, Vx, name, savePath, cm, figWidth, figHeight);
    return;
end
if nargin < 13 || isempty(realVectorSpacingBase)
    realVectorSpacingBase = 500;
end
targetSamples = max(14, round(1.4 * sqrt(realVectorSpacingBase)));

fig = makeBaseFigure(figWidth, figHeight);
imagesc(X(1, :), Y(:, 1), real(Vx));
axis equal tight;
set(gca, 'YDir', 'normal');
colorbar;
colormap(cm);
xlabel('x [m]');
ylabel('y [m]');
title(name, 'Interpreter', 'none');
set(gca, 'FontSize', chooseFontSize(figWidth));
climVal = prctile(abs(real(Vx(:))), 95);
if climVal > 0
    clim([-1, 1] * climVal);
end
hold on;
[qX, qY, qU, qV] = buildCountNormalizedQuiver(X, Y, Vx, Vy, targetSamples);
quiver(qX, qY, qU, qV, 1, 'Color', 'c');
writeSvgPng(fig, fullfile(savePath, name));
close(fig);
end

function exportReconstructionFigure(X, Y, Vx, Vy, name, savePath, cm, figWidth, figHeight, ~, useVectorFields, vectorSpacingBase)
fig = makeBaseFigure(figWidth, figHeight);
img = imagesc(X(1,:), Y(:,1), real(Vx));
axis equal tight;
set(gca, 'YDir', 'normal');
colorbar;
colormap(cm);
title(name, 'Interpreter', 'none');
xlabel('x [m]');
ylabel('y [m]');
set(gca, 'FontSize', chooseFontSize(figWidth));
set(img, 'Interpolation', 'bilinear');
climVal = prctile(abs(real(Vx(:))), 95);
if climVal > 0
    clim([-1, 1] * climVal);
end
if useVectorFields
    hold on;
    targetSamples = max(12, round(sqrt(vectorSpacingBase)));
    [qX, qY, qU, qV] = buildCountNormalizedQuiver(X, Y, Vx, Vy, targetSamples);
    quiver(qX, qY, qU, qV, 1, 'Color', 'c');
end
writeSvgPng(fig, fullfile(savePath, name));
close(fig);
end

function exportZoomedFourierFigure(X, Y, Vx, Vy, name, savePath, figWidth, figHeight, gridSize, fourierZoomFactor, fourierUseLog, useVectorFields, fourierVectorSpacingBase)
if nargin < 11
    fourierUseLog = false;
end
if nargin < 12 || isempty(useVectorFields)
    useVectorFields = true;
end
if nargin < 13 || isempty(fourierVectorSpacingBase)
    fourierVectorSpacingBase = 25;
end

[Xz, Yz, Vxz, Vyz] = cropCenteredGrid(X, Y, Vx, Vy, fourierZoomFactor);
ampField = abs(Vxz.^2 + Vyz.^2);
if fourierUseLog
    imageField = log(1 + ampField);
    plotTitle = 'log of abs squared';
else
    imageField = ampField;
    plotTitle = 'amp abs squared';
end

fig = makeBaseFigure(figWidth, figHeight);
imagesc(Xz(1,:), Yz(:,1), imageField);
axis equal tight;
set(gca, 'YDir', 'normal');
colorbar;
colormap(loadSunsetColormap());
title(name, 'Interpreter', 'none');
xlabel('k_x [1/m]');
ylabel('k_y [1/m]');
set(gca, 'FontSize', chooseFontSize(figWidth));
if useVectorFields
    hold on;
    downSampleFactor = max(1, round(gridSize / (fourierZoomFactor * fourierVectorSpacingBase)) + 1);
    [qX, qY, qU, qV] = buildNormalizedQuiver(Xz, Yz, Vxz, Vyz, downSampleFactor);
    quiver(qX, qY, qU, qV, 1, 'Color', 'c');
end
writeSvgPng(fig, fullfile(savePath, name));
close(fig);
end

function fig = makeBaseFigure(figWidth, figHeight)
svgScale = 1 / 1.25;
fig = figure('Visible', 'off', 'Color', 'w', 'Units', 'pixels', ...
    'Position', [100 100 round(figWidth * svgScale) round(figHeight * svgScale)]);
end

function [qX, qY, qU, qV] = buildNormalizedQuiver(X, Y, Vx, Vy, downSampleFactor)
if nargin < 5 || isempty(downSampleFactor)
    downSampleFactor = 4;
end
step = max(1, downSampleFactor^2);
Vmag = sqrt(real(Vx).^2 + real(Vy).^2);
nz = Vmag > 0;
VxNorm = zeros(size(Vx));
VyNorm = zeros(size(Vy));
VxNorm(nz) = real(Vx(nz)) ./ Vmag(nz);
VyNorm(nz) = real(Vy(nz)) ./ Vmag(nz);
qX = X(1:step:end);
qY = Y(1:step:end);
qU = VxNorm(1:step:end);
qV = VyNorm(1:step:end);
end

function [qX, qY, qU, qV] = buildCountNormalizedQuiver(X, Y, Vx, Vy, targetSamples)
if nargin < 5 || isempty(targetSamples)
    targetSamples = 20;
end
Vmag = sqrt(real(Vx).^2 + real(Vy).^2);
nz = Vmag > 0;
VxNorm = zeros(size(Vx));
VyNorm = zeros(size(Vy));
VxNorm(nz) = real(Vx(nz)) ./ Vmag(nz);
VyNorm(nz) = real(Vy(nz)) ./ Vmag(nz);
rowIdx = unique(round(linspace(1, size(X, 1), targetSamples)));
colIdx = unique(round(linspace(1, size(X, 2), targetSamples)));
qX = X(rowIdx, colIdx);
qY = Y(rowIdx, colIdx);
qU = VxNorm(rowIdx, colIdx);
qV = VyNorm(rowIdx, colIdx);
end

function [Xz, Yz, Vxz, Vyz] = cropCenteredGrid(X, Y, Vx, Vy, zoomFactor)
if nargin < 5 || isempty(zoomFactor) || zoomFactor <= 1
    Xz = X;
    Yz = Y;
    Vxz = Vx;
    Vyz = Vy;
    return;
end

gridSize = size(X, 1);
cutElements = round(gridSize * 0.5 * (zoomFactor - 1) / zoomFactor);
cutElements = max(0, min(cutElements, floor((gridSize - 1) / 2)));
idx = (cutElements + 1):(gridSize - cutElements);
Xz = X(idx, idx);
Yz = Y(idx, idx);
Vxz = Vx(idx, idx);
Vyz = Vy(idx, idx);
end

function applyCenteredWindow(ax, X, Y, zoomFactor)
if nargin < 4 || isempty(zoomFactor) || zoomFactor <= 1
    return;
end
[xLimits, yLimits] = centeredWindowLimits(X, Y, zoomFactor);
xlim(ax, xLimits);
ylim(ax, yLimits);
end

function [xLimits, yLimits] = centeredWindowLimits(X, Y, zoomFactor)
if nargin < 3 || isempty(zoomFactor) || zoomFactor <= 1
    xLimits = [X(1,1), X(1,end)];
    yLimits = [Y(1,1), Y(end,1)];
    return;
end
xCenter = 0.5 * (X(1,1) + X(1,end));
yCenter = 0.5 * (Y(1,1) + Y(end,1));
xSpan = (X(1,end) - X(1,1)) / zoomFactor;
ySpan = (Y(end,1) - Y(1,1)) / zoomFactor;
xLimits = xCenter + 0.5 * [-xSpan, xSpan];
yLimits = yCenter + 0.5 * [-ySpan, ySpan];
end

function writeSvgPng(fig, basePath)
svgPath = [basePath, '.svg'];
pngPath = [basePath, '.png'];
try
    print(fig, '-dsvg', svgPath);
catch
    exportgraphics(fig, svgPath, 'ContentType', 'vector');
end
try
    drawnow;
    set(fig, 'InvertHardcopy', 'off');
    print(fig, pngPath, '-dpng', '-r200', '-opengl');
catch
    exportgraphics(fig, pngPath, 'Resolution', 200);
end
end

function fontSize = chooseFontSize(figWidth)
if figWidth >= 1200
    fontSize = 10;
else
    fontSize = 9;
end
end

function cm = loadSunsetColormap()
rootDir = fileparts(mfilename('fullpath'));
cmPath = fullfile(rootDir, 'sunset_cm.mat');
if exist(cmPath, 'file')
    tmp = load(cmPath);
    if isfield(tmp, 'sunset')
        cm = tmp.sunset;
        return;
    end
end
cm = parula(256);
end

function cm = loadDefaultColormap(rootDir)
cmPath = fullfile(rootDir, 'cm.mat');
if exist(cmPath, 'file')
    tmp = load(cmPath, 'cm');
    if isfield(tmp, 'cm')
        cm = tmp.cm;
        return;
    end
end
cm = parula(256);
end

function ensureDir(folderPath)
if ~exist(folderPath, 'dir')
    mkdir(folderPath);
end
end
