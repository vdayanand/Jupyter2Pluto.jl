
# Jupyter2Pluto
### convert Jupyter notebook into [Pluto.jl](https://github.com/fonsp/Pluto.jl) notebook

``` julia
    using Pkg
    Pkg.add("Jupyter2Pluto")
    using Jupyter2Pluto
    jupyter2pluto("sample.ipynb")
```
Pluto notebook `sample.jl` will be created in the working directory

### convert [Pluto.jl](https://github.com/fonsp/Pluto.jl) notebook into Jupyter notebook
``` julia
    pluto2jupyter("sample.jl")
```
Jupyter notebook `sample.ipynb` will be created in the working directory
