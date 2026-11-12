function requireSpace(out)
    f=java.io.File(char(out));
    available=double(f.getUsableSpace());
    assert(available>=512*1024^2,'study:DiskSpace', ...
        'Only %.0f MiB free; 512 MiB reserve required for new checkpoints.',  available/1024^2);
end
