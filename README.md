# Jupyter2Pluto
## convert Jupyter notebook into [Pluto.jl](https://github.com/fonsp/Pluto.jl) notebook
### Quickstart
``` julia
    ] add http://github.com/vdayanand/Jupyter2Pluto.jl
    using Jupyter2Pluto
    convert_notebook("sample.ipynb")
```
Pluto notebook `sample.ipynb.jl` will be created in the directory where notebook `sample.ipynb` file is located
