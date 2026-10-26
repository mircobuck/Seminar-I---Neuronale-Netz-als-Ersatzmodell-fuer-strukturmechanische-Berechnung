function out=predictLegacy(id,artifact,X,services)
%PREDICTLEGACY Explicit adapter to unchanged historical implementations.
if nargin<4, services=struct; end
switch string(id)
    case {"Scalar_GPR","POD_GP","POD_RBF","POD_MLP","Beam_plus_GPR"}
        out=predict_surrogate(artifact,X);
    case "Beam_theory"
        out=beam_tip(X);
    case "POD_Galerkin"
        assert(isfield(services,'mesh'),'ROM mesh and online assembly service required.');
        out=cell(size(X,1),1);
        for i=1:size(X,1)
            [out{i}.field,out{i}.scalars,~,out{i}.timing,out{i}.diagnostics]= ...
                rom_predict(services.mesh,artifact.V,X(i,:));
        end
    case "DeepONet"
        assert(isfield(services,'xi'),'DeepONet query coordinates required.');
        out=predict_deeponet(artifact,X,services.xi);
    otherwise
        error('femstudy:model:Unknown','Unknown legacy model.');
end
end
