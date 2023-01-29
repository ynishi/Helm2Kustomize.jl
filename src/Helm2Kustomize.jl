module Helm2Kustomize

using YAML
using OrderedCollections
using Comonicon
using UUIDs

export Config, init

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

const KUSTOMIZATION_FILENAME = "kustomization.yaml"
CONFIG = Config()

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
        throw(error("out dir exists $OUT_DIR`"))
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
    mkpath(config.tempdir)
end

function down()
    @debug "down"
end

function make_template()
    @info "make_template"
end

function make_kustomize()
    @info "make_kustomize"
end

function mv_kustomize()
    @info "mv_kustomize"
end

@main function helm2kustomize(repo::String; outdir::String="", version::String="", templatepath::String="", configfile::String="config.yaml", force::Bool=false, base::Bool=false, keep::Bool=false)

    p = pwd()

    try
        global CONFIG = init(repository, outdir, version, templatepath, configfile, force, base, keep)
        up()
        make_template()
        make_kustomize()
        cd(p)
        mv_kustomize()
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
