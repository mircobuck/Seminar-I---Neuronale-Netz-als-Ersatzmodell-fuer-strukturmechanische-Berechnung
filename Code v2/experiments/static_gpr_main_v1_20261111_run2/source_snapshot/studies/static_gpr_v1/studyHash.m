function hash=studyHash(filename)
fid=fopen(filename,'rb'); assert(fid>=0,'study:HashRead','Cannot open %s',filename);
closer=onCleanup(@()fclose(fid)); md=java.security.MessageDigest.getInstance('SHA-256');
while true
    bytes=fread(fid,2^20,'*uint8'); if isempty(bytes), break; end
    md.update(typecast(bytes,'int8'));
end
hash=lower(reshape(dec2hex(typecast(md.digest(),'uint8'),2)',1,[]));
end
