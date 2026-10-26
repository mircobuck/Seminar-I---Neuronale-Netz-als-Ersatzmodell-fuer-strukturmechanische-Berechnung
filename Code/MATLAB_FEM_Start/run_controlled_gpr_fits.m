function varargout = run_controlled_gpr_fits(varargin)
%run_controlled_gpr_fits Backward-compatible entry point. See scripts/matlab/run_controlled_gpr_fits_impl.m.
warning('','Use the documented project entry points; this compatibility wrapper will remain during migration.');
if nargout
    [varargout{1:nargout}] = run_controlled_gpr_fits_impl(varargin{:});
else
    run_controlled_gpr_fits_impl(varargin{:});
end
end
