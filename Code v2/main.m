function main(mode)
%MAIN Generate static and modal FEM reference datasets.
% main("smoke") runs a small separate check; main("all") runs all splits.
% Historical mixed static/modal generation. Explicit modes remain available.
if nargin==0
    fprintf('Historical mixed static/modal FEM entry. Use runStaticStudy for the current static comparison.\n');
    fprintf('Explicit legacy modes: main("smoke"), main("train_val"), main("test"), main("all").\n');
    return
end
mode=string(validatestring(char(mode),{'all','smoke','train_val','test'}));
% Pfade relativ zu dieser Datei bestimmen, unabh?ngig vom Installationsort.
root=fileparts(mfilename('fullpath'));
runner=fullfile(root,'scripts','matlab');
addpath(runner);
cleanup=onCleanup(@()rmpath(runner));
% Der Probelauf verwendet eigene Fallzahlen und einen separaten Ausgabeordner.
if mode=="smoke"
    configFile=fullfile(root,'data_generation','configs','smoke_v1.json');
    out=fullfile(root,'data_generation','smoke');
else
    configFile=fullfile(root,'data_generation','configs','data_generation_v1.json');
    out=fullfile(root,'data_generation','data');
end
fprintf('FEM workflow: %s; output: %s\n',mode,out);
% Das Design legt Parameter und Split jedes Falls vor der FEM-Berechnung fest.
run_data_generation_v2("design",configFile,out);
if mode~="test"
    run_data_generation_v2("static_train_val",configFile,out);
    run_data_generation_v2("modal_train_val",configFile,out);
end
% F?r eine unabh?ngige Bewertung Testf?lle erst nach der Modellauswahl berechnen.
if mode=="all" || mode=="test" || mode=="smoke"
    run_data_generation_v2("static_test",configFile,out);
    run_data_generation_v2("modal_test",configFile,out);
end
fprintf('FEM workflow complete. Results: %s\n',out);
end
