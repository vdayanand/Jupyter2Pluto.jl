# Jupyter2Pluto
### convert Jupyter notebook into [Pluto.jl](https://github.com/fonsp/Pluto.jl) notebook

``` julia
    ] add http://github.com/vdayanand/Jupyter2Pluto.jl
    using Jupyter2Pluto
    jupyter2pluto("sample.ipynb")
```
Pluto notebook `sample.ipynb.jl` will be created in the working directory

### convert [Pluto.jl](https://github.com/fonsp/Pluto.jl) notebook into Jupyter notebook
``` julia
    pluto2jupyter("sample.jl")
```
Jupyter notebook `sample.jl.ipynb` will be created in the working directory
