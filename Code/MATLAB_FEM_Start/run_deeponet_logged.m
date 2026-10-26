function varargout = run_deeponet_logged(varargin)
%run_deeponet_logged Backward-compatible entry point. See scripts/matlab/run_deeponet_logged_impl.m.
warning('','Use the documented project entry points; this compatibility wrapper will remain during migration.');
if nargout
    [varargout{1:nargout}] = run_deeponet_logged_impl(varargin{:});
else
    run_deeponet_logged_impl(varargin{:});
end
end
