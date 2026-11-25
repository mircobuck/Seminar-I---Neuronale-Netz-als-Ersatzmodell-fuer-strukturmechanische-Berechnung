function c = contract(task)
%contract Return task-specific parameter, output and unit conventions.
task = string(task);
assert(isscalar(task) && any(task==["static","modal"]),'surrogate:contract:Task', ...
    'Expected static displacement fields or modal frequencies.');
if task=="modal"
    c=struct('parameterNames',["L_m","b_m","h_m","E_Pa","nu","rho_kg_m3"], ...
        'parameterUnits',["m","m","m","Pa","1","kg/m^3"], ...
        'outputUnit',"Hz",'version',"surrogate-modal-v1",'task',task,'modeIndices',(1:6)');
    return
end
c.parameterNames = ["L_m","b_m","h_m","E_Pa","nu","Fz_N"];
c.parameterUnits = ["m","m","m","Pa","1","N"];
c.outputUnit = "m";
c.version = "surrogate-v1";
c.task = task;
[a,b,d] = ndgrid(linspace(0,1,21),linspace(0,1,5),linspace(0,1,5));
c.grid = [a(:)';b(:)';d(:)'];
end
