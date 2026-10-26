function varargout = run_training_size_study(varargin)
%run_training_size_study Backward-compatible entry point. See scripts/matlab/run_training_size_study_impl.m.
warning('','Use the documented project entry points; this compatibility wrapper will remain during migration.');
if nargout
    [varargout{1:nargout}] = run_training_size_study_impl(varargin{:});
else
    run_training_size_study_impl(varargin{:});
end
end
