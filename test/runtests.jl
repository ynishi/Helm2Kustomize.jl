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
        force = true
        config = init(repository, outdir, version, templatepath, configfile, force, base, keep)

        @test "tmp_dir" == config.outdir
        @test "" != config.tempdir
        @test "group/repository" == config.helm_repository
        @test "1.0.0" == config.helm_version
        @test 1 == length(keys(config.helm_options))
        @test "optionName" == config.helm_options[1][:name]
        @test "optionValue" == config.helm_options[1][:value]
        @test "templatepath" == config.templatepath
        @test "$(config.tempdir)/templatepath/templates" == config.templatedir
        @test 1 == length(keys(config.dict))
        @test config.isforce
        @test config.isbase
        @test config.iskeep

        config2 = init(repository, outdir, version, "", configfile, force, base, keep)
        @test "$(config2.tempdir)/repository/templates" == config2.templatedir

        config3 = init(repository, outdir, version, templatepath, "", false, false, false)
        @test 0 == length(keys(config3.helm_options))
        @test 0 == length(keys(config3.dict))
        @test !config3.isforce
        @test !config3.isbase
        @test !config3.iskeep
    end

    @testset "up" begin
        config = Config()
        config.tempdir = "up_tempdir_test"
        isdir(config.tempdir) && rm(config.tempdir, force=true, recursive=true)
        setconfig(config)
        up()
        @test isdir(config.tempdir)
        testfilepath = joinpath(config.tempdir, "testfile")
        touch(testfilepath)

        up()
        @test isdir(config.tempdir)
        @test !isfile(testfilepath)

        rm(config.tempdir, force=true, recursive=true)
    end

    @testset "down" begin
        config = Config()
        config.tempdir = "down_tempdir_test"
        isdir(config.tempdir) && rm(config.tempdir, force=true, recursive=true)
        mkpath(config.tempdir)
        setconfig(config)
        down()
        @test !isdir(config.tempdir)
        @test !isfile(config.tempdir)
    end

    @testset "make_template_cmd" begin
        config = Config()
        config.helm_repository = "group/repository"
        config.helm_version = "1.0.0"
        config.tempdir = "tempdir"
        config.helm_options = [Dict(:name => "--option-name", :value => "optionValue")]
        setconfig(config)
        got = make_template_cmd()
        @test `helm template 'group/repository' --version '1.0.0' --output-dir 'tempdir' '--option-name optionValue'` == got
    end

    @testset "make_kustomize_paths" begin
        config = Config()
        config.templatedir = "testtemplatedir"
        setconfig(config)
        got = make_kustomize_paths()
        @test [
            "testtemplatedir/template1" => [],
            "testtemplatedir/template2" => [],
            "testtemplatedir" => ["template1", "template2"],
            "testtemplatedir/template2/template2_1" => [],
            "testtemplatedir/template2" => ["template2_1"],
        ] == got
    end
end
