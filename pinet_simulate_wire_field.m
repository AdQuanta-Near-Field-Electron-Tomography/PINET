function [E_x, E_y, k_elec, k_free] = pinet_simulate_wire_field(x, y, params)
%PINET_SIMULATE_WIRE_FIELD Simulate the analytic scattered wire field.

%% Convert the beam and optical parameters to wave numbers
electon_energy_rest = params.RestEnergyKeV;
electron_energy = params.ElectronEnergyKeV;
v_over_c = sqrt(1 - (electon_energy_rest / (electron_energy + electon_energy_rest))^2);
k_free = 2 * pi / params.WaveLength;
k_elec = k_free / v_over_c;

%% Evaluate the field inside and outside the wire
E_x = zeros(size(x));
E_y = zeros(size(x));

field_limit = max(x(:));
r = [x(:), y(:)];
r_mag = sqrt(r(:, 1).^2 + r(:, 2).^2);
phi = atan2(y, x);

condition1 = r_mag <= params.WireRadius;
condition2 = (r_mag <= field_limit) & (r_mag > params.WireRadius);

%% Choose between the static and phase-bearing field variants
useStaticVariant = isfield(params, 'FieldVariant') && strcmpi(params.FieldVariant, 'static');
if useStaticVariant
    E_x(condition1) = params.E0 * (2 * params.Epsilon2 / (params.Epsilon1 + params.Epsilon2) - 1);
    E_x(condition2) = params.E0 ...
        .* ((params.Epsilon1 - params.Epsilon2) / (params.Epsilon1 + params.Epsilon2)) ...
        .* (params.WireRadius^2 ./ r_mag(condition2).^2) ...
        .* (1 - 2 * sin(phi(condition2)).^2);
    E_y(condition2) = 2 * params.E0 ...
        .* ((params.Epsilon1 - params.Epsilon2) / (params.Epsilon1 + params.Epsilon2)) ...
        .* params.WireRadius^2 ./ r_mag(condition2).^2 ...
        .* sin(phi(condition2)) .* cos(phi(condition2));
else
    E_x(condition1) = params.E0 * (2 * params.Epsilon2 / (params.Epsilon1 + params.Epsilon2) - 1) ...
        .* exp(1i * k_free * r_mag(condition1));
    E_x(condition2) = params.E0 * exp(1i * k_free * r_mag(condition2)) ...
        .* ((params.Epsilon1 - params.Epsilon2) / (params.Epsilon1 + params.Epsilon2)) ...
        .* (params.WireRadius^2 ./ r_mag(condition2).^2) ...
        .* (1 - 2 * sin(phi(condition2)).^2);
    E_y(condition2) = 2 * params.E0 * exp(1i * k_free * r_mag(condition2)) ...
        .* ((params.Epsilon1 - params.Epsilon2) / (params.Epsilon1 + params.Epsilon2)) ...
        .* params.WireRadius^2 ./ r_mag(condition2).^2 ...
        .* sin(phi(condition2)) .* cos(phi(condition2));
end
end
