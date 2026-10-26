%% Analytische Berechnung eines einseitig eingespannten Balkens
% Euler-Bernoulli-Balkentheorie
% Einzellast am freien Ende
%
% Einheitensystem: SI
% Länge         [mm]
% Kraft         [N]
% Elastizität   [Pa] bzw [N/mm^2*1e6]
% Durchbiegung  [mm]

clear;
clc;
close all;

%% 1. Geometrie

L = 1000;                       % Balkenlänge [mm]
b = 50;                         % Breite des rechteckigen Querschnitts [mm]
h = 100;                        % Höhe des Querschnitts [mm]

%% 2. Materialeigenschaften

material.E = 210000;            % Emodul [N/mm^2] hier: Stahl
material.nu = 0.30;             % Poissonzahl [-]
material.rho = 7.85*1e-6;       % Dichte [kg/mm^3]

% Orthotropes Material (z.B. Holz oder Faserverbund):
% material.Ex  = 210000;        % Emodul in x-Richtung [N/mm^2]
% material.Ey  = 10000;         % Emodul in y-Richtung [N/mm^2]
% material.Ez  = 10000;         % Emodul in z-Richtung [N/mm^2]
% material.Gxy = 5000;          % Schubmodul [N/mm^2]
% material.Gxz = 5000;          % Schubmodul [N/mm^2]
% material.Gyz = 3000;          % Schubmodul [N/mm^2]
% material.nuxy = 0.30;         % Querkontraktionszahl [-]

%% 3. Belastung

F = 100;                        % Kraft am freien Ende [N]

% Vorzeichenkonvention:
% F > 0: Kraft wirkt in positiver Durchbiegungsrichtung.
% F < 0: Kraft wirkt in negativer Durchbiegungsrichtung.

%% 4. Berechnung der Querschnittswerte

A = b * h;                      % Querschnittsfläche [mm^2]
I = b * h^3 / 12;               % Flächenträgheitsmoment [mm^4]

E = material.E;

%% 5. Analytische Durchbiegung

n = 101;                        % Anzahl der Auswertepositionen
x = linspace(0, L, n);

% Biegelinie nach Euler-Bernoulli
w = (F ./ (6*E*I)) .* (3*L*x.^2 - x.^3);

% Maximale Durchbiegung am freien Ende
w_max = F * L^3 / (3*E*I);

%% 6. Biegemoment und Biegespannung

% Biegemoment F*L aber für jedes x
M = abs(F) .* (L - x);

% Maximale Biegespannung am Balkenanfang
sigma_max = abs(F) * L * (h/2) / I;

%% 7. Ergebnisse ausgeben

fprintf('\n--- Analytische Balkenberechnung ---\n');
fprintf('Balkenlänge:              %.4f mm\n', L);
fprintf('Breite:                   %.4f mm\n', b);
fprintf('Höhe:                     %.4f mm\n', h);
fprintf('Elastizitätsmodul:        %.3f MPa\n', E);
fprintf('Kraft:                    %.2f N\n', F);
fprintf('Querschnittsfläche:       %.6e mm^2\n', A);
fprintf('Flächenträgheitsmoment:   %.6e mm^4\n', I);
fprintf('Max. Durchbiegung:        %.6f mm\n', w_max);
fprintf('Max. Biegespannung:       %.3f MPa\n', sigma_max);

%% 8. Durchbiegung plotten

figure;

plot(x, w, 'b-', 'LineWidth', 2);
grid on;

xlabel('Position x [mm]');
ylabel('Durchbiegung w(x) [mm]');
title('Analytische Durchbiegung des Kragträgers');

%% 9. Biegemoment plotten

figure;

plot(x, M, 'r-', 'LineWidth', 2);
grid on;

xlabel('Position x [mm]');
ylabel('Biegemoment |M(x)| [Nmm]');
title('Biegemoment entlang des Balkens');