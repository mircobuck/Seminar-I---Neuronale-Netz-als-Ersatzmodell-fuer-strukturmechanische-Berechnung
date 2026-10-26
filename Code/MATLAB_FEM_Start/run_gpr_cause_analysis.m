function varargout = run_gpr_cause_analysis(varargin)
%run_gpr_cause_analysis Backward-compatible entry point. See scripts/matlab/run_gpr_cause_analysis_impl.m.
warning('','Use the documented project entry points; this compatibility wrapper will remain during migration.');
if nargout
    [varargout{1:nargout}] = run_gpr_cause_analysis_impl(varargin{:});
else
    run_gpr_cause_analysis_impl(varargin{:});
end
end
