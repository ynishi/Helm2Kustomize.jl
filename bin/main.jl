using Pkg;
Pkg.activate(".");

using Comonicon
using Helm2Kustomize

@main function helm2kustomize(
    repository::String;
    outdir::String="",
    version::String="",
    templatepath::String="",
    configfile::String="config.yaml",
    force::Bool=false,
    base::Bool=false,
    keep::Bool=false
)
    Helm2Kustomize.helm2kustomize(
        repository;
        outdir=outdir,
        version=version,
        templatepath=templatepath,
        configfile=configfile,
        force=force,
        base=base,
        keep=keep
    )
end