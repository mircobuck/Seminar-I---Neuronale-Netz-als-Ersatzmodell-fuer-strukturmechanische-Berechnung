function out=subset(D,ids)
%SUBSET Select complete physical cases, preserving common spatial metadata.
out=D; out.X=D.X(ids,:); out.id=D.id(ids);
if isfield(D,'S'), out.S=D.S(:,ids); end
if isfield(D,'F'), out.F=D.F(ids,:); end
if isfield(D,'Y'), out.Y=D.Y(ids,:); end
if isfield(D,'seconds'), out.seconds=D.seconds(ids); end
if isfield(D,'nodes'), out.nodes=D.nodes(ids); end
end
