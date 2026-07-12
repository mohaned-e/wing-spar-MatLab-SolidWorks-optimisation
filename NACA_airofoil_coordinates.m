clear, clc

%% Chordwise stations
n_points = 100;
beta = linspace(0, pi, n_points);
x = (1 - cos(beta)) / 2;   % cosine spacing - denser points near leading/trailing edge

%% Thickness distribution
T = 0.18;   % max thickness as a fraction of chord (last two digits of 4418 / 100)
yt = 5 * T * (0.2969*sqrt(x) - 0.126*x - 0.3516*x.^2 + 0.2843*x.^3 - 0.1015*x.^4);
%plot(x, yt); axis equal;   % checkpoint - checks thickness distribution looks like a smooth teardrop

%% Camber line
M = 0.04;   % max camber (%), first digit of 4418 / 100
P = 0.4;    % position of max camber (tenths of chord), second digit of 4418 / 10
yc = zeros(size(x));           % preallocate - creates an array of zeros the same size as x, to be filled in
front = x < P;                 % logical array: true where x is before the camber peak, false after
yc(front)  = (M/P^2) * (2*P*x(front) - x(front).^2);                                    % rise: applies to all true (front) values
yc(~front) = (M/(1-P)^2) * ((1-2*P) + 2*P*x(~front) - x(~front).^2);                    % fall: applies to all false (~front) values
%plot(x, yc); axis equal;   % checkpoint - checks the camber line is smooth with no kink at the peak
dyc_dx = zeros(size(x));       % preallocate - camber line slope at each point
dyc_dx(front)  = (2*M/P^2) * (P - x(front));            % rise slope
dyc_dx(~front) = (2*M/(1-P)^2) * (P - x(~front));        % fall slope
theta = atan(dyc_dx);   % convert slope (ratio) into an angle, so it can be used to rotate the thickness offset

%% Upper and lower surfaces
% Thickness is applied perpendicular to the camber line (not straight up/down),
% using sin/cos of theta to split that perpendicular offset into x and y components.
xu = x - yt.*sin(theta);   yu = yc + yt.*cos(theta);   % upper surface
xl = x + yt.*sin(theta);   yl = yc - yt.*cos(theta);   % lower surface
%plot(xu, yu, xl, yl); axis equal; legend("upper", "lower")   % checkpoint - checks the shape looks like a real cambered aerofoil

%% Combining into one curve
xu_reversed = flip(xu);   yu_reversed = flip(yu);   % flip the upper curve so it runs trailing edge -> leading edge
x_loop = [xu_reversed, xl(2:end)];   % merge the two curves into one, ready to export to SolidWorks
y_loop = [yu_reversed, yl(2:end)];   % start xl/yl from the 2nd point (not the 1st) to avoid a duplicated point where the two curves meet
%plot(x_loop, y_loop); axis equal

%% Exporting coordinate file to solidworks
chord_mm = 300; %actualy lenght of wing chord
x_export = x_loop *chord_mm; % scaling the x coordinates for exporting
y_export = y_loop * chord_mm; % scalimg the y coordinates for exporting
z_export = zeros(size(x_export)); % it is a 2d shape so the z coodinates will all be zero
data = [x_export', y_export', z_export']; % combining the all the coordinates in to one data set and using ' to convert data going in row to go into columes


where_to_store = "C:\Users\mohan\Desktop\Automated Wing Spar Structural Optimisation (MATLAB + SolidWorks)";
file_name = fullfile(where_to_store, "naca4418.txt"); % fullfile joins the file path with the file name together
writematrix(data, file_name, "Delimiter", "tab", "FileType", "text");
%writematrix(data, ...), save data as an file on computer
% fullfile joins the file path with the file name together
%'Delimiter', 'tab' — separates the X, Y, Z values with a tab character. So SolidWorks can tell where each column ends and the next one begins.
%'FileType', 'text' — makes sure it saves as a plain text file, not some other format.


