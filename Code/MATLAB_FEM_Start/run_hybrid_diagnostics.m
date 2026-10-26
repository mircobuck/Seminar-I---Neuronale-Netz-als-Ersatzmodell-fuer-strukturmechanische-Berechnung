function varargout = run_hybrid_diagnostics(varargin)
%run_hybrid_diagnostics Backward-compatible entry point. See scripts/matlab/run_hybrid_diagnostics_impl.m.
warning('','Use the documented project entry points; this compatibility wrapper will remain during migration.');
if nargout
    [varargout{1:nargout}] = run_hybrid_diagnostics_impl(varargin{:});
else
    run_hybrid_diagnostics_impl(varargin{:});
end
end
