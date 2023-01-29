module Helm2Kustomize

using YAML
using OrderedCollections
using Comonicon
using UUIDs

export Config, setconfig, getconfig,
    init, up, down,
    make_template_cmd, make_kustomize_paths, create_kustomization, cp_kustomize,
    helm2kustomize

Base.@kwdef mutable struct Config
    outdir::String = ""
    tempdir::String = ""
    helm_repository::String = ""
    helm_version::String = ""
    helm_options::Vector{Dict} = []
    templatepath::String = ""
    templatedir::String = ""
    dict::Dict{Symbol,Any} = Dict()
    isforce::Bool = false
    isbase::Bool = false
    iskeep::Bool = false
end

setconfig(config) = global CONFIG = config
getconfig() = CONFIG


const KUSTOMIZATION_FILENAME = "kustomization.yaml"
CONFIG = Config()

function check()
    for cmd in ["helm", "kustomize"]
        checkcmd(cmd)
    end
end

function checkcmd(cmd)
    out = Pipe()
    proc = run(pipeline(`$cmd --help`, stdout=out, stderr=out))
    close(out.in)
    if proc.exitcode != 0
        throw(error("not found $cmd excutable"))
    end
end

function init(
    repository::String,
    outdir::String,
    version::String,
    templatepath::String,
    configfile::String,
    force::Bool,
    base::Bool,
    keep::Bool)

    @debug "init"
    config::Config = Config()

    if repository == ""
        throw(error("empty repo"))
    end

    config.helm_repository = repository

    splitted = split(config.helm_repository, "/")
    if length(splitted) == 0
        throw(error("invalid repo name"))
    end
    repolast = last(splitted)

    config.outdir = outdir == "" ? "$(repolast)_out" : outdir

    config.isforce = force

    if !config.isforce &&
       (isdir(config.outdir) || isfile(config.outdir))
        throw(error("out dir exists $config.outdir"))
    end

    config.helm_version = version

    config.templatepath = templatepath == "" ? repolast : templatepath

    config.tempdir = gettemppath()
    if config.tempdir == ""
        throw(error("failed to create temp dir name"))
    end
    config.templatedir = joinpath(config.tempdir, config.templatepath, "templates")

    if isfile(configfile)
        config.dict = YAML.load_file(configfile, dicttype=Dict{Symbol,Any})
    end
    if haskey(config.dict, :helm) && haskey(config.dict[:helm], :options)
        config.helm_options = config.dict[:helm][:options]
    end

    config.isbase = base
    config.iskeep = keep

    @debug config
    config
end

function gettemppath()
    joinpath(pwd(), "tmp_" * string(uuid1()))
end

function up()
    @debug "up"
    cleartemp()
    mkpath(CONFIG.tempdir)
end

function down()
    @debug "down"
    cleartemp()
end

cleartemp() = rm(CONFIG.tempdir, force=true, recursive=true)

function make_template_cmd()
    @info "make_template_cmd"
    options = length(CONFIG.helm_options) > 0 ? reduce(vcat,
        map(option -> [option[:name], option[:value]], CONFIG.helm_options)) : []
    `helm template $(CONFIG.helm_repository) --version $(CONFIG.helm_version) --output-dir $(CONFIG.tempdir) $options`
end

function make_kustomize_paths()
    @info "make_kustomize_paths"
    paths = []
    for (root, dirs, _) in walkdir(CONFIG.templatedir)
        for dir in dirs
            append!(paths, (Dict(abspath(root, dir) => [])))
        end
        if length(dirs) == 0
            continue
        end
        append!(paths, (Dict(abspath(root) => dirs)))
    end
    paths
end

abspath(path...) = joinpath(CONFIG.tempdir, path...)

function create_kustomization(path, dirs=[])
    cd(path)
    @info "create kustomization: $(pwd())"
    if isfile(KUSTOMIZATION_FILENAME)
        return
    end
    run(`kustomize create --autodetect`)

    if length(dirs) == 0
        return
    end
    root_kustomization = YAML.load_file(KUSTOMIZATION_FILENAME, dicttype=OrderedDict{String,Any})
    root_kustomization["resources"] = map(dir -> "./$dir", dirs)
    YAML.write_file(KUSTOMIZATION_FILENAME, root_kustomization)
end

function cp_kustomize()
    @info "cp_kustomize"
    if !CONFIG.isforce && isdir(CONFIG.outdir)
        throw(error("out dir is exist"))
    end
    rm(CONFIG.outdir, force=true, recursive=true)
    todir = CONFIG.isbase ? joinpath(CONFIG.outdir, "base") : CONFIG.outdir
    mkpath(dirname(todir))
    cp(CONFIG.templatedir, todir)
end

function helm2kustomize(
    repository::String;
    outdir::String="",
    version::String="",
    templatepath::String="",
    configfile::String="config.yaml",
    force::Bool=false,
    base::Bool=false,
    keep::Bool=false
)

    rundir = pwd()
    try
        check()
        global CONFIG = init(repository, outdir, version, templatepath, configfile, force, base, keep)
        up()
        run(make_template_cmd())
        for (path, dirs) in make_kustomize_paths()
            create_kustomization(path, dirs)
        end
        cd(rundir)
        cp_kustomize()
        @info "run, kustomize build $(CONFIG.outdir) | kubectl appy -f -"
        if !CONFIG.iskeep
            down()
        end
    catch e
        @error "error occured to run helm2kustomize"
        rethrow(e)
    end
end

end
