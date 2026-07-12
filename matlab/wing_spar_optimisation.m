clear, clc

%% ---- Fixed inputs ----
g = 9.81;            % gravity (m/s^2)
LF = 2.5;            % load factor
ac_mass = 0.55;      % aircraft mass (kg) - used for point_load
S = 1.5;             % span (m)
D = 58;              % material density (kg/m^3)
UTS_c = 1e6;         % ultimate compressive strength (Pa) - governing limit
G_shear = 2.1e7;     % shear modulus (Pa)
T_test = 10;         % reference test torque (Nm)

chord_mm = 300;      % aerofoil chord length (mm)
x_center = 0.3;      % spar location as a fraction of the chord length (30% chord)
T_naca = 0.18;       % aerofoil max thickness fraction
M_naca = 0.04;       % aerofoil max camber fraction
P_naca = 0.4;        % camber location fraction

%% ---- Derived loading values ----
PL = LF * ac_mass * g / 2;    % point load at wing tip (N)
semi_S = S / 2;               % semispan (m)
M_root = PL * semi_S;         % bending moment at wing root (Nm)

%% ---- Search space ----
height_option = 0.025:0.001:0.06;   % candidate heights (m)
width_option  = 0.025:0.001:0.1;    % candidate widths (m)

vertical_thickness = 0.005:0.005:0.050;   % candidate top/bottom wall thickness (m)
horizontal_thickness = 0.005:0.005:0.050; % candidate side wall thickness (m)


%% ---- Track the lightest passing design ----
best_mass   = inf;
best_height = NaN;
best_width  = NaN;
best_ht = NaN;
best_wt = NaN;

for h = height_option
    for w = width_option   % nested loops -> test every height/width combination

        % Check the spar actually fits inside the real aerofoil shape at
        % this width - checked at both edges of the box, not just the
        % centre, since the aerofoil tapers thinner away from x_center.
        x_start_frac = x_center - (w/2)/(chord_mm/1000);   % edge of spar closest to the leading edge
        x_end_frac   = x_center + (w/2)/(chord_mm/1000);   % edge of spar furthest from the leading edge

        [yu_start, yl_start] = local_aerofoil_height(x_start_frac, T_naca, M_naca, P_naca, chord_mm); % aerofoil upper/lower surface at the start edge
        [yu_end, yl_end]     = local_aerofoil_height(x_end_frac, T_naca, M_naca, P_naca, chord_mm);   % aerofoil upper/lower surface at the end edge

        top_limit    = min(yu_start, yu_end);   % tightest ceiling, regardless of which edge it comes from
        bottom_limit = max(yl_start, yl_end);   % tightest floor, regardless of which edge it comes from

        safety_margin_mm = 6;   % 3mm real clearance on both the top and bottom (6mm total)
        true_band = top_limit - bottom_limit - safety_margin_mm;   % usable height after margin (mm)
        max_height = true_band / 1000;                              % converted to metres, to match h

        for ht = vertical_thickness
            for wt = horizontal_thickness
                A = (w*h) - (w - 2*wt)*(h - 2*ht);           % cross-sectional area (m^2)
                I = (w*h^3 - (w - 2*wt)*(h - 2*ht)^3) / 12;  % second moment of area (m^4)
                sigma = M_root * (h/2) / I;                  % peak bending stress (Pa)
                RF = UTS_c / sigma;                          % reserve factor (pass if >= 1)

                Am = (w - wt) * (h - ht);                                  % enclosed midline area (m^2)
                LI = 2*(w - wt)/ht + 2*(h - ht)/wt;                        % perimeter/thickness sum (dimensionless)
                J  = 4 * Am^2 / LI;                                        % torsion constant (m^4)
                theta_deg = rad2deg(T_test * semi_S / (G_shear * J));      % twist under T_test (deg)
                compliance = theta_deg / T_test;                           % twist per unit torque (deg/Nm), pass if <= 3

                spar_mass = D * A * S;   % full-span spar mass (kg) - what we're minimising

                if w > (2 * wt) && h > (2 * ht) && RF >= 1 && compliance <= 3 && h < max_height && spar_mass < best_mass  % all conditions must be met to update
                    best_mass   = spar_mass;
                    best_height = h;
                    best_width  = w;
                    best_ht = ht;
                    best_wt = wt;

                end
            end 
        end
    end
end

%% ---- Vertical placement of the winning design ----
% Recalculated here using best_width specifically, rather than reusing
% the loop's leftover variables - those would still hold values from the
% LAST width tried, not the actual best width found.
x_start_frac = x_center - (best_width / 2) / (chord_mm / 1000);
x_end_frac   = x_center + (best_width / 2) / (chord_mm / 1000);

[yu_start, yl_start] = local_aerofoil_height(x_start_frac, T_naca, M_naca, P_naca, chord_mm);
[yu_end, yl_end]     = local_aerofoil_height(x_end_frac, T_naca, M_naca, P_naca, chord_mm);

top_limit    = min(yu_start, yu_end);
bottom_limit = max(yl_start, yl_end);

spar_centre_y = (top_limit + bottom_limit) / 2;   % midpoint between the two limits - centres the spar with even clearance top/bottom

%% ---- Results ----
disp("best design: height = " + best_height + "m, width = " + best_width + "m, vertical thickness = "+ best_ht +"m, horizontal thickness = "+ best_wt +"m, mass = " + best_mass + "kg")
disp("spar placement: " + x_center * chord_mm + "mm from the leading edge, " + spar_centre_y + "mm above (0,0)")
