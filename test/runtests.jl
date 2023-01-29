using Helm2Kustomize
using Test

@testset "Helm2Kustomize.jl" begin
    @testset "init" begin
        repository = "group/repository"
        outdir = "tmp_dir"
        version = "1.0.0"
        templatepath = "templatepath"
        configfile = "configtest.yaml"
        base = true
        keep = true
        force = false
        config = init(repository, outdir, version, templatepath, configfile, force, base, keep)

        @test config.outdir == "tmp_dir"
        @test config.tempdir != ""
        @test config.helm_repository == "group/repository"
        @test config.helm_version == "1.0.0"
        @test length(keys(config.helm_options)) == 1
        @test config.helm_options[1][:name] == "optionName"
        @test config.helm_options[1][:value] == "optionValue"
        @test config.templatepath == "templatepath"
        @test config.templatedir == "$(config.tempdir)/templatepath/templates"
        @test length(keys(config.dict)) == 1
        @test config.isforce == false
        @test config.isbase
        @test config.iskeep

        config2 = init(repository, outdir, version, "", configfile, force, base, keep)
        @test config2.templatedir == "$(config2.tempdir)/repository/templates"

        config3 = init(repository, outdir, version, templatepath, "", force, base, keep)
        @error config3
        @test length(keys(config3.helm_options)) == 0
        @test length(keys(config3.dict)) == 0
    end
end
