function result=field(S,H,w,X)
%FIELD Per-case volume-normalized vector RMS and component errors in SI.
assert(isequal(size(S),size(H)) && size(S,1)==numel(w));
assert(all(isfinite(S),'all') && all(isfinite(H),'all'));
q=size(S,1)/3; assert(q==floor(q)); w=w(:);
result.absoluteRMS=sqrt(sum(w.*(H-S).^2,1))';
den=sqrt(sum(w.*S.^2,1))';
result.relative=result.absoluteRMS./den;
result.relative(den==0)=NaN;
result.physicalL2=result.absoluteRMS.*sqrt(prod(X(:,1:3),2));
for c=1:3
    ids=(c-1)*q+(1:q); wc=w(ids)/sum(w(ids));
    a=sqrt(sum(wc.*(H(ids,:)-S(ids,:)).^2,1))';
    b=sqrt(sum(wc.*S(ids,:).^2,1))';
    result.componentAbsolute(:,c)=a;
    r=a./b; r(b==0)=NaN; result.componentRelative(:,c)=r;
end
e=sort(result.relative); e=e(isfinite(e));
result.summary=[median(e),e(ceil(.95*numel(e))),max(e)];
end
