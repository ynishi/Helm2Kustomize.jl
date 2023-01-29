module Helm2Kustomize

using YAML
using OrderedCollections
using Comonicon
using UUIDs

Base.@kwdef struct Config
    outdir::String = ""
    tempdir::String = ""
    helm_repository::String = ""
    helm_version::String = ""
    helm_options::Dict = Dict()
    templatepath::String = ""
    templatedir::String = ""
    dict::Dict{Symbol,Any} = Dict()
    isforce::Bool = false
    isbase::Bool = false
    iskeep::Bool = false
end

const KUSTOMIZATION_FILENAME = "kustomization.yaml"
CONFIG = Config()

function init(repo, outdir, version, templatepath, force, config, base, keep)
    @debug "init"
    Config()
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

@main function helm2kustomize(repo::String; outdir::String="", version::String="", templatepath::String="", config::String="config.yaml", force::Bool=false, base::Bool=false, keep::Bool=false)

    p = pwd()

    try
        global CONFIG = init(repo, outdir, version, templatepath, force, config, base, keep)
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
