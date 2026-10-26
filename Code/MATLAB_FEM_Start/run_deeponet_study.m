function varargout = run_deeponet_study(varargin)
%run_deeponet_study Backward-compatible entry point. See scripts/matlab/run_deeponet_study_impl.m.
warning('','Use the documented project entry points; this compatibility wrapper will remain during migration.');
if nargout
    [varargout{1:nargout}] = run_deeponet_study_impl(varargin{:});
else
    run_deeponet_study_impl(varargin{:});
end
end
