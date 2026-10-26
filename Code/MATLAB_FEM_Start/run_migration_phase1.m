function varargout = run_migration_phase1(varargin)
%run_migration_phase1 Backward-compatible entry point. See scripts/matlab/run_migration_phase1_impl.m.
warning('','Use the documented project entry points; this compatibility wrapper will remain during migration.');
if nargout
    [varargout{1:nargout}] = run_migration_phase1_impl(varargin{:});
else
    run_migration_phase1_impl(varargin{:});
end
end
