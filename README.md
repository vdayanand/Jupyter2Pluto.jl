
# Jupyter2Pluto

Jupyter2Pluto is a Julia package that allows you to convert Jupyter notebooks into [Pluto.jl](https://github.com/fonsp/Pluto.jl) notebooks and vice versa. 
## Installation

You can install Jupyter2Pluto using the Julia package manager. Open a Julia REPL and run the following commands:

```julia
using Pkg
Pkg.add("Jupyter2Pluto")
```

## Converting Jupyter to Pluto

To convert a Jupyter notebook into a Pluto notebook, use the following Julia code snippet after installing Jupyter2Pluto:

```julia
using Jupyter2Pluto
jupyter2pluto("sample.ipynb")
```

This command will create a new Pluto notebook named `sample.jl` in your current working directory.

## Converting Pluto to Jupyter

If you have a Pluto notebook and want to convert it to a Jupyter notebook, simply use the following Julia code:

```julia
pluto2jupyter("sample.jl")
```
## Contributions
 If you'd like to improve the package, fix issues, or add new features, please consider contributing to the project. 
