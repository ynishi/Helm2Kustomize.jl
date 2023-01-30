# Helm2Kustomize

[![Build Status](https://travis-ci.com/ynishi/Helm2Kustomize.jl.svg?branch=main)](https://travis-ci.com/ynishi/Helm2Kustomize.jl)
[![Coverage](https://codecov.io/gh/ynishi/Helm2Kustomize.jl/branch/main/graph/badge.svg)](https://codecov.io/gh/ynishi/Helm2Kustomize.jl)
[![Coverage](https://coveralls.io/repos/github/ynishi/Helm2Kustomize.jl/badge.svg?branch=main)](https://coveralls.io/github/ynishi/Helm2Kustomize.jl?branch=main)

Julia package for convert helm to kustomize.

## required

- Helm cli(verion 3 or later)
- Kustomize cli

## usage

- add pkg

```
using Pkg; Pkg.add(url="https://github.com/ynishi/Helm2Kustomize.jl")
```

- setup path

```
ln -s $(pwd)/bin/helm2kustomize ${any bin dir}/helm2kustomize
# refresh path
```

- run

```
helm2kustomize ${repository/path_to_chart} [options]
```
