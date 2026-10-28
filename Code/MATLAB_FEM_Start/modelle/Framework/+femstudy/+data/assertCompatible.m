function assertCompatible(a,b)
% Identity and metadata, not dimensions, establish operator compatibility.
required={'schema','spaceID','units','ordering','constraints'};
for k=1:numel(required)
    name=required{k};
    assert(isfield(a,name)&&isfield(b,name)&&isequal(a.(name),b.(name)), ...
        'femstudy:space:Incompatible','Incompatible or missing spatial metadata: %s',name);
end
end
