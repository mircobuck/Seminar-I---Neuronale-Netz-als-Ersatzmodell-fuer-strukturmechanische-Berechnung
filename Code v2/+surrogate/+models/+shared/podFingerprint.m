function hash = podFingerprint(data)
%podFingerprint Identify training fields, weights and ordered case IDs.
md=java.security.MessageDigest.getInstance('SHA-256');
parts={double(data.caseIds(:)),double(data.displacementComponentWeights(:)), ...
    double(data.displacementFields),double(data.inputParameters)};
for k=1:numel(parts)
    x=parts{k}; md.update(typecast(uint64(size(x)),'int8'));
    md.update(typecast(x(:),'int8'));
end
hash=lower(reshape(dec2hex(typecast(md.digest(),'uint8'),2).',1,[]));
end
