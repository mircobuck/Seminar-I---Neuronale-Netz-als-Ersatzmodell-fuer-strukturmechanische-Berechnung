function c = contract(task)
%contract Return the parameter and output conventions for a task.
task = string(task);
switch task
    case "static"
        c.parameterNames = ["L_m","b_m","h_m","E_Pa","nu","Fz_N"];
        c.parameterUnits = ["m","m","m","Pa","1","N"];
        c.outputUnit = "m";
    case "modal"
        c.parameterNames = ["L_m","b_m","h_m","E_Pa","nu","rho_kg_m3"];
        c.parameterUnits = ["m","m","m","Pa","1","kg/m^3"];
        c.outputUnit = "Hz";
    otherwise
        error('surrogate:contract:Task','Unknown task: %s',task);
end
c.version = "surrogate-v1";
c.task = task;
[a,b,d] = ndgrid(linspace(0,1,21),linspace(0,1,5),linspace(0,1,5));
c.grid = [a(:)';b(:)';d(:)'];
end
