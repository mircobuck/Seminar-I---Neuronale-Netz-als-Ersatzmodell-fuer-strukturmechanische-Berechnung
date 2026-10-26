function A=pod_encode(P,S)
A=(P.V'*(P.w.*(S-P.mean)))';
end
