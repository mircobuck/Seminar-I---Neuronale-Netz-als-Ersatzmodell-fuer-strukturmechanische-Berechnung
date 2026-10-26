function e=field_error(S,H,w)
num=sqrt(sum(w.*(S-H).^2,1)); den=sqrt(sum(w.*S.^2,1));
e=(num./max(den,1e-14))';
end
