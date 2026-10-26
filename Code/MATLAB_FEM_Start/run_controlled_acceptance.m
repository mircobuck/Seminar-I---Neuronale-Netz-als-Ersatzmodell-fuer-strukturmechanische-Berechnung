function varargout = run_controlled_acceptance(varargin)
%run_controlled_acceptance Backward-compatible entry point. See scripts/matlab/run_controlled_acceptance_impl.m.
warning('','Use the documented project entry points; this compatibility wrapper will remain during migration.');
if nargout
    [varargout{1:nargout}] = run_controlled_acceptance_impl(varargin{:});
else
    run_controlled_acceptance_impl(varargin{:});
end
end
