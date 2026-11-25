function [Y,w] = targets(data)
%targets Internal output-by-case matrix; public task fields keep their units.
switch string(data.modality)
    case "static"
        Y=double(data.displacementFields);
        w=double(data.displacementComponentWeights(:));
    case "modal"
        Y=double(data.frequencyHz');
        w=ones(6,1);
    otherwise
        error('surrogate:contract:Task','Unknown task.');
end
end
