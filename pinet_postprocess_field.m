function [Rec_E_x_blur, Rec_E_y_blur, Rec_E_x_med, Rec_E_y_med, pm_Rec_E_x, pm_Rec_E_y] = ...
    pinet_postprocess_field(Rec_E_x, Rec_E_y, params)
%PINET_POSTPROCESS_FIELD Apply the original smoothing chain.

%% Gaussian blur
if params.GaussianSigma > 0 && exist('imgaussfilt', 'file')
    Rec_E_x_blur = complex( ...
        imgaussfilt(real(Rec_E_x), params.GaussianSigma), ...
        imgaussfilt(imag(Rec_E_x), params.GaussianSigma));
    Rec_E_y_blur = complex( ...
        imgaussfilt(real(Rec_E_y), params.GaussianSigma), ...
        imgaussfilt(imag(Rec_E_y), params.GaussianSigma));
else
    Rec_E_x_blur = Rec_E_x;
    Rec_E_y_blur = Rec_E_y;
end

%% Median filter
if exist('medfilt2', 'file')
    medFilterSize = max(1, floor(0.07 * params.GridSize^0.8));
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

%% Perona-Malik diffusion
pm_Rec_E_x = peronaMalikDiffusion(Rec_E_x_med, params.PeronaIterations, params.PeronaK, params.PeronaDeltaT);
pm_Rec_E_y = peronaMalikDiffusion(Rec_E_y_med, params.PeronaIterations, params.PeronaK, params.PeronaDeltaT);
end

function diffusedImage = peronaMalikDiffusion(image, numIterations, k, delta_t)
%PERONAMALIKDIFFUSION Diffuse the real and imaginary parts separately.
realPart = peronaMalikReal(real(image), numIterations, k, delta_t);
imagPart = peronaMalikReal(imag(image), numIterations, k, delta_t);
diffusedImage = complex(realPart, imagPart);
end

function diffusedImage = peronaMalikReal(image, numIterations, k, delta_t)
%PERONAMALIKREAL Standard Perona-Malik update on one real-valued image.
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

    diffusedImage = diffusedImage + delta_t * ( ...
        cN .* north + cS .* south + cE .* east + cW .* west);
end
end
