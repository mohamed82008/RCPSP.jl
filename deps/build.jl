function get_os()
    if Sys.KERNEL == :NT
        os = :Windows
    else
        os = Sys.KERNEL
    end
    return os
end

function get_files(n)
    @assert n in (30, 60, 90, 120)
    tarball = "j$n.sm.tgz"
    cd("..") do 
        rm("downloads", force=true, recursive=true)
        @info("Downloading PSPLIB files")
        mkpath("downloads")
        file = "downloads/$tarball"
        try
            url = "http://www.om-db.wi.tum.de/psplib/files/$tarball"
            download("https://$url", file)
        catch
            url = "www.om-db.wi.tum.de/psplib/files/$tarball"
            try
                download("https://$url", file)
            catch
                @info("Using insecure connection")
                try
                    download("http://$url", file)
                catch
                    @info("Cannot download PSPLIB files")
                end
            end
        end
        os = get_os()
        isdir("projects") || mkdir("projects")
        cd("projects") do 
            isdir("$n") || mkdir("$n")
            cd("$n") do
                if os == :Windows
                    home = Sys.BINDIR
                    success(`$home/7z x ../../downloads/$tarball -y`)
                    rm("../../downloads/$tarball")
                    tarball = tarball[1:end-3]
                    success(`$home/7z x $tarball -y -ttar`)
                    rm(tarball)
                else
                    run(`tar xzf ../../downloads/$tarball`)
                    rm("../../downloads/$tarball")
                end
            end
        end
        rm("downloads", force=true, recursive=true)
    end
end

for n in (30, 60, 90, 120)
    get_files(n)
end
