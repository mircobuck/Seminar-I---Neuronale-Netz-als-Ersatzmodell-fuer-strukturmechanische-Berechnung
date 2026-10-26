function varargout = run_hybrid_static_audit(varargin)
%run_hybrid_static_audit Backward-compatible entry point. See scripts/matlab/run_hybrid_static_audit_impl.m.
warning('','Use the documented project entry points; this compatibility wrapper will remain during migration.');
if nargout
    [varargout{1:nargout}] = run_hybrid_static_audit_impl(varargin{:});
else
    run_hybrid_static_audit_impl(varargin{:});
end
end
