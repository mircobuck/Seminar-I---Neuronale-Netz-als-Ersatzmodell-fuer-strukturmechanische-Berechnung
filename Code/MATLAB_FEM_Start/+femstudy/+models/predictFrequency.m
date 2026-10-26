function p=predictFrequency(model,X)
Z=(X-model.xm)./model.xs; raw=zeros(size(X,1),numel(model.net));
for j=1:numel(model.net)
    raw(:,j)=exp(model.ym(j)+model.ys(j)*predict(model.net{j},Z));
end
p.rawHz=raw; p.sortedHz=sort(raw,2); p.orderViolation=any(diff(raw,1,2)<0,2);
end
