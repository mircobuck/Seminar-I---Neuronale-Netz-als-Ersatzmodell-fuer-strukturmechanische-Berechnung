function [H,y,u,timing,diagnostics]=rom_predict(mesh,V,x)
%rom_predict - Solve a POD-Galerkin ROM with complete online assembly
%   [H,Y,U,TIMING,DIAGNOSTICS] = rom_predict(MESH,V,X) assembles the
%   mechanical system, projects it, solves it and reconstructs outputs.
%   See also rom_assemble
total=tic;
[K,f,~,timing]=rom_assemble(mesh,x);
t=tic; Kr=V'*(K*V); fr=V'*f; timing.ProjectionSeconds=toc(t);
t=tic; a=Kr\fr; timing.ReducedSolveSeconds=toc(t);
t=tic; u=V*a; H=mesh.O*u;
nq=size(mesh.xi,2); mag=sqrt(sum(reshape(H,nq,3).^2,2));
y=[H(2*nq+mesh.tipIndex),max(mag)];
timing.ReconstructionSeconds=toc(t); timing.OnlineSeconds=toc(total);
% Residual and energy diagnostics deliberately excluded from online timing.
diagnostics.Residual=norm(K*u-f)/norm(f);
diagnostics.ProjectedResidual=norm(V'*(K*u-f))/max(norm(fr),realmin);
diagnostics.Symmetry=norm(Kr-Kr','fro')/norm(Kr,'fro');
[~,diagnostics.CholeskyFlag]=chol((Kr+Kr')/2);
end
