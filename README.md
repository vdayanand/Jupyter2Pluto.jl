<img width="162" alt="image" src="https://user-images.githubusercontent.com/31879758/229309153-b00491a8-b0ee-47f2-b43e-5a8564af9333.png">

# Jupyter2Pluto
### convert Jupyter notebook into [Pluto.jl](https://github.com/fonsp/Pluto.jl) notebook

``` julia
    ] add http://github.com/vdayanand/Jupyter2Pluto.jl
    using Jupyter2Pluto
    jupyter2pluto("sample.ipynb")
```
Pluto notebook `sample.jl` will be created in the working directory

### convert [Pluto.jl](https://github.com/fonsp/Pluto.jl) notebook into Jupyter notebook
``` julia
    pluto2jupyter("sample.jl")
```
Jupyter notebook `sample.ipynb` will be created in the working directory
