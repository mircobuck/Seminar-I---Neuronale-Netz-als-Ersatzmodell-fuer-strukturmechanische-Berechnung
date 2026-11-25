function setupProject
%setupProject Add the active study and FEM folders to the MATLAB path.
root = fileparts(mfilename('fullpath'));
addpath(root, fullfile(root,'workflows','static_comparison'), ...
    fullfile(root,'workflows','modal_comparison'), ...
    fullfile(root,'fem_core'), fullfile(root,'fem_core','src'), '-begin');
end
