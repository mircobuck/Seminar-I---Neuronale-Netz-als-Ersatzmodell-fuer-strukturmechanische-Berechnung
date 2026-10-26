function varargout = run_project(varargin)
%run_project Backward-compatible entry point. See scripts/matlab/run_project_impl.m.
warning('','Use the documented project entry points; this compatibility wrapper will remain during migration.');
if nargout
    [varargout{1:nargout}] = run_project_impl(varargin{:});
else
    run_project_impl(varargin{:});
end
end
