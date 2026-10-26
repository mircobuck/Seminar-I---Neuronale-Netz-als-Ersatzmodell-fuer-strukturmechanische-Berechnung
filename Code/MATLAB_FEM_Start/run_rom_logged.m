function varargout = run_rom_logged(varargin)
%run_rom_logged Backward-compatible entry point. See scripts/matlab/run_rom_logged_impl.m.
warning('','Use the documented project entry points; this compatibility wrapper will remain during migration.');
if nargout
    [varargout{1:nargout}] = run_rom_logged_impl(varargin{:});
else
    run_rom_logged_impl(varargin{:});
end
end
