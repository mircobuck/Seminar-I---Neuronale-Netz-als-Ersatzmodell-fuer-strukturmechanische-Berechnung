function cleanup = setupProject
%setupProject Activate only the current static workflow until cleanup is cleared.
% Keep the returned onCleanup object alive for the desired scope.
root = fileparts(mfilename('fullpath'));
previousPath = path;
cleanup = onCleanup(@() path(previousPath));
addpath(root, fullfile(root,'workflows','static_comparison'), '-begin');
end
