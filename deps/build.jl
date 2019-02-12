function get_files(n)
    @assert n in (30, 60, 90, 120)
    tarball = "j$n.sm.tgz"
    cd("..") do 
        rm("downloads", force=true, recursive=true)
        @info("Downloading PSPLIB files")
        mkpath("downloads")
        file = "downloads/$tarball"
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
        isdir("projects") || mkdir("projects")
        cd("projects") do 
            isdir("$n") || mkdir("$n")
            cd("$n") do
                run(`tar xzf ../../downloads/$tarball`)
                rm("../../downloads/$tarball")
            end
        end
        rm("downloads", force=true, recursive=true)
    end
end

for n in (30, 60, 90, 120)
    get_files(n)
end
