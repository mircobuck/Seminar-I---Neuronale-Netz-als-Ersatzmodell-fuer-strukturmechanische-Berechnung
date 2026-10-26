function Y=predict_reg(M,X)
Z=(X-M.xm)./M.xs;
switch M.kind
    case "gp"
        Y=repmat(M.ym,size(X,1),1);
        for j=1:numel(M.net)
            if ~M.fixed(j), Y(:,j)=M.ym(j)+M.ys(j)*predict(M.net{j},Z); end
        end
    case "rbf"
        D=sqrt(max(0,sum(Z.^2,2)+sum(M.X.^2,2)'-2*Z*M.X'));
        Y=[D.^3,ones(size(Z,1),1),Z]*M.coef;
    case "mlp"
        Y=double(minibatchpredict(M.net,single(Z),ExecutionEnvironment="cpu"));
        Y=Y.*M.ys+M.ym;
    otherwise, error('Unknown regressor.');
end
end
