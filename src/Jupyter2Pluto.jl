module Jupyter2Pluto
using JSON
using UUIDs

const _notebook_header = "### A Pluto.jl notebook ###"
const _cell_id_delimiter = "# ╔═╡ "
const _order_delimiter = "# ╠═"
const _order_delimiter_folded = "# ╟─"
const _cell_suffix = "\n\n"

export convert_notebook

abstract type JupyterCell end

struct JupyterCodeCell <: JupyterCell
    content::Vector{String}
end
struct JupyterMarkdownCell <: JupyterCell
    content::String
end

abstract type PlutoCell end

struct PlutoCodeCell <: PlutoCell
    cell_id::UUID
    content::String
end

struct PlutoBlockCodeCell <: PlutoCell
    cell_id::UUID
    content::String
end

struct PlutoMarkdownCell <: PlutoCell
    cell_id::UUID
    content::String
end

function Base.show(io::IO, cell::PlutoCodeCell)
    gl = """
$(_cell_id_delimiter)$(cell.cell_id)
$(cell.content)$(_cell_suffix)"""
    print(io, gl)
end

function Base.show(io::IO, cell::PlutoBlockCodeCell)
    gl = """
$(_cell_id_delimiter)$(cell.cell_id)
begin\n$(cell.content)\nend$(_cell_suffix)"""
    print(io, gl)
end


function Base.show(io::IO, cell::PlutoMarkdownCell)
    content = replace(cell.content, "\"" => "\\\"")
    r = """
$(_cell_id_delimiter)$(cell.cell_id)
md\"
$(content)
\"$(_cell_suffix)"""
    print(io, r)
end

function cell_id()
    uuid4()
end

function generate_code(pcells::Vector{PlutoCell})
    pheader = _notebook_header*"\n\n"
    codestring = "$pheader$(join(pcells))$(order_code(pcells))"
    return codestring
end

function order_code(pcells::Vector{PlutoCell})
    orderstrprefix = "$(_cell_id_delimiter)Cell order:\n"
    orderstrprefix *join(order_code.(pcells))
end

function order_code(pcell::PlutoMarkdownCell)
    return _order_delimiter_folded*""*string(pcell.cell_id)*"\n"
end

function order_code(pcell::Union{PlutoCodeCell, PlutoBlockCodeCell})
   return _order_delimiter*""*string(pcell.cell_id)*"\n"
end

function generate_plutocells(codecell::JupyterCodeCell)
    pcells = PlutoCell[]
    for content in codecell.content
        id = cell_id()
        push!(pcells, PlutoCodeCell(id, content))
    end
    return pcells
end

function PlutoCell(codecell::JupyterCodeCell)
    id = cell_id()
    if has_multiple_expressions(codecell)
        return PlutoBlockCodeCell(id, join(codecell.content))
    end
    return PlutoCodeCell(id, join(codecell.content))
end

function PlutoCell(codecell::JupyterMarkdownCell)
    id = cell_id()
    return PlutoMarkdownCell(id, codecell.content)
end

function has_multiple_expressions(codecell::JupyterCodeCell)
    expressions = Meta.parse("begin "*join(codecell.content, "\n")*" end").args
    filter!(x -> !(x isa LineNumberNode), expressions)
    length(expressions) > 1
end

function convert_file(jupyter_file)
    jupyter_cells = try
        content = JSON.parsefile(jupyter_file)
        content["cells"]
    catch ex
        error("Jupyter notebook parse error")
    end
    pluto_cells = PlutoCell[]
    for cell in jupyter_cells
        !haskey(cell, "cell_type") || !haskey(cell,"source") && continue
        if cell["cell_type"] == "markdown" && !isempty(cell["source"])
            pc = PlutoCell(JupyterMarkdownCell(join(cell["source"])))
            push!(pluto_cells, pc)
        end
        if cell["cell_type"] == "code" && !isempty(cell["source"])
            pc = PlutoCell(JupyterCodeCell(cell["source"]))
            push!(pluto_cells, pc)
        end
    end
    output = generate_code(pluto_cells)
    dest = "$(jupyter_file).jl"
    open(dest, "w") do f
        write(f, output)
    end
    dest
end

function convert_notebook(file)
    convert_file(file)
end
end # module