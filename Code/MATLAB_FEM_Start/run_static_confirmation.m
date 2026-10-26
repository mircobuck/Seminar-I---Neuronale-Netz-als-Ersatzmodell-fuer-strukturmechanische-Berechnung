function varargout = run_static_confirmation(varargin)
%run_static_confirmation Backward-compatible entry point. See scripts/matlab/run_static_confirmation_impl.m.
warning('','Use the documented project entry points; this compatibility wrapper will remain during migration.');
if nargout
    [varargout{1:nargout}] = run_static_confirmation_impl(varargin{:});
else
    run_static_confirmation_impl(varargin{:});
end
end
