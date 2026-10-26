function P=rom_observation(nodes,elements,points)
%rom_observation - Build consistent quadratic tetrahedral observations
%   P = rom_observation(NODES,ELEMENTS,POINTS) maps scalar nodal values to
%   reference points, using actual midpoint positions to identify edges.
%   See also triangulation, pointLocation
T=triangulation(elements(1:4,:)',nodes');
[tet,bary]=pointLocation(T,points');
assert(all(isfinite(tet)),'Observation point outside reference mesh.');
pairs=nchoosek(1:4,2); nr=size(points,2);
columns=zeros(nr,10); values=zeros(nr,10);
for q=1:nr
    ids=elements(:,tet(q)); L=bary(q,:);
    columns(q,:)=ids'; values(q,1:4)=L.*(2*L-1);
    for k=5:10
        distances=zeros(6,1);
        for j=1:6
            midpoint=mean(nodes(:,ids(pairs(j,:))),2);
            distances(j)=norm(nodes(:,ids(k))-midpoint);
        end
        [distance,j]=min(distances);
        assert(distance<1e-10,'Quadratic edge-node mapping failed.');
        values(q,k)=4*L(pairs(j,1))*L(pairs(j,2));
    end
end
rows=repmat((1:nr)',1,10);
P=sparse(rows(:),columns(:),values(:),nr,size(nodes,2));
assert(norm(P*ones(size(nodes,2),1)-1,Inf)<1e-12);
assert(norm(P*nodes'-points',Inf)<1e-10);
end
