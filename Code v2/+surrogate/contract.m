function c = contract(task)
%contract Return the static parameter, field and unit conventions.
task = string(task);
assert(isscalar(task) && task=="static",'surrogate:contract:Task', ...
    'Only static displacement fields are supported.');
c.parameterNames = ["L_m","b_m","h_m","E_Pa","nu","Fz_N"];
c.parameterUnits = ["m","m","m","Pa","1","N"];
c.outputUnit = "m";
c.version = "surrogate-v1";
c.task = task;
[a,b,d] = ndgrid(linspace(0,1,21),linspace(0,1,5),linspace(0,1,5));
c.grid = [a(:)';b(:)';d(:)'];
end
