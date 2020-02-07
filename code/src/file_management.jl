# This function should be called from within
# $DIR/smc/nyfed_dsge/SMCProject/specfiles/<vintage>/spec<whatever the name is>.jl
# right after the "module" SMCProject.jl is loaded in.
# It initializes the saveroot directory and creates the relevant symlinks from the saveroot
# to the corresponding vintaged specfile directory and vice versa for ease of navigation between the two
# if they do not already exist.
function initialize_directory_structure(project_root::String = "SMC_DIR")

    # Initialize root paths
    spec_root    = project_root * "/specfiles"
    results_root = project_root * "/results"
    save_root    = project_root * "/save"

    # Asset that you are in the specfiles directory
    current_dir = pwd()
    @assert occursin(spec_root, current_dir) "You need to be in SMCProject/specfiles to initialize the directory structure."

    # Verify that the sub-directory that you are currently in is a valid one
    current_subdir = current_dir[length(spec_root)+2:end]
    verify_valid_subdir(current_subdir)

    # Create the vintaged file dirs in /results and /save
    spec_dir    = spec_root * "/" * current_subdir
    results_dir = results_root * "/" * current_subdir
    save_dir    = save_root * "/" * current_subdir
    dirs = [results_dir, save_dir]
    for dir in dirs
        if isdir(dir)
            @warn "The dir $dir already exists. Aborting creation of a new directory."
        else
            mkpath(dir)
            println("Created $dir")
        end
    end

    # Populate all vintaged file dirs with the symlinks to each of the other dirs
    sym_links = ["/results", "/save", "/spec"]
    dirs = [results_dir, save_dir, spec_dir]
    for target_dir in dirs
        cd(target_dir)
        for (dir, link) in zip(dirs, sym_links)
            # Don't create a symlink to a directory within the same directory
            if contains(target_dir, link)
                continue
            end
            if isdir(target_dir * link)
                @warn "The symbolic link $(target_dir * link) already exists. Aborting creation of a new link."
            else
                run(`ln -s $dir $(target_dir * link)`)
                println("Created the symbolic link $(target_dir * link)")
            end
        end
    end
end

# Verify the sub-directory is in YYMMDD format
function verify_valid_subdir(subdir::String)
    @assert length(subdir) == 6

    # Verify the YY is either 2018 or later
    @assert Meta.parse(subdir[1:2]) >= 18 "Invalid sub-directory year. These files are expected to have been generated in 2018 or onward."

    # Verify the MM and DD are valid months and days
    @assert Meta.parse(subdir[3:4]) in 1:12 "Invalid sub-directory month. The MM in the YYMMDD date format must be within 1-12"
    @assert Meta.parse(subdir[5:6]) in 1:31 "Invalid sub-directory day. The DD in the YYMMDD date format must be within 1-31"
end
