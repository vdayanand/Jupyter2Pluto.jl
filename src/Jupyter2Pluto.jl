module Jupyter2Pluto
using JSON
using UUIDs

const _notebook_header = "### A Pluto.jl notebook ###"
const _cell_id_delimiter = "# ╔═╡ "
const _order_delimiter = "# ╠═"
const _order_delimiter_folded = "# ╟─"
const _cell_suffix = "\n\n"

export pluto2jupyter, jupyter2pluto

abstract type JupyterCell end

struct JupyterCodeCell <: JupyterCell
    execution_count::Union{Int, Nothing}
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
md\"\"\"
$(content)\"\"\"$(_cell_suffix)"""
    print(io, r)
end

function Base.Dict(cell::JupyterMarkdownCell)
    source = String[]
    content_list = split(cell.content, "\n")
    for (i, content) in enumerate(content_list)
        i == length(cell.content) && (push!(source, content); continue)
        push!(source, content*"\n")
    end
    Dict(
        "cell_type" => "markdown",
        "metadata"=>Dict(),
        "source"=> source
    )
end

function Base.Dict(cell::JupyterCodeCell)
    source = String[]
    for (i, content) in enumerate(cell.content)
        (isempty(content) || i == length(cell.content)) && (push!(source, content); continue)
        push!(source, content*"\n")
    end
    Dict(
        "cell_type" => "code",
        "execution_count" => cell.execution_count,
        "metadata"=>Dict(),
            "outputs"=>[],
            "source"=> source
    )
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
        return PlutoBlockCodeCell(id, join("    ".*codecell.content))
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

function jupyter2pluto(jupyter_file)
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
            jmark_cell = JupyterMarkdownCell(join(cell["source"]))
            pc = PlutoCell(jmark_cell)
            push!(pluto_cells, pc)
        end
        if cell["cell_type"] == "code" && !isempty(cell["source"])
            jcode_cell = JupyterCodeCell(cell["execution_count"],cell["source"])
            pc = PlutoCell(jcode_cell)
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

function parse_pluto_cell(rawcell::String)
    cellist = string.(split(rawcell, '\n'))
    body = join(cellist[2:end], '\n')
    multiline_mdr = r"md\"\"\"(.*)\"\"\""s
    line_mdr = r"md\"(.*)\""s
    matches = if (mat = match(multiline_mdr, body)) != nothing
        mat
    else
        match(line_mdr, body)
    end

    if matches != nothing
        PlutoMarkdownCell(UUID(cellist[1]), matches.captures[1])
    else
        PlutoCodeCell(UUID(cellist[1]), body)
    end
end

function parse_pluto_end(rawcell::String)
    main_split= string.(split(rawcell, _order_delimiter))
    orderids = String[]
    for order in main_split
        splits = string.(split(order, _order_delimiter_folded))
        for split in splits
            !isempty(split) && push!(orderids, strip(split))
        end
    end
    orderids[2:end]
end

function order(pcells::Vector{PlutoCell}, orderids::Vector{String})
    sorted_pcells = PlutoCell[]
    for orderid in orderids
        for pcell in pcells
            if occursin(string(pcell.cell_id),  orderid)
                push!(sorted_pcells, pcell)
            end
        end
    end
    return sorted_pcells
end

let
    global JupyterCell
    global parse_pluto_load
    execution_count = 1
    function parse_pluto_load(raw::AbstractString)
        jcell = JupyterCodeCell(execution_count, split(raw, "\n"))
        execution_count += 1
        jcell
    end
    function JupyterCell(pcell::PlutoCodeCell)
        jcell = JupyterCodeCell(execution_count,split(pcell.content, "\n"))
        execution_count += 1
        jcell
    end
end

function JupyterCell(pcell::PlutoMarkdownCell)
    content = pcell.content
    JupyterMarkdownCell(pcell.content)
end

function pluto2jupyter(file)
    # parser: pluto notebook has orderidlist, map(order_id => codesnippets) ::Plutocells
    plutoraw = readchomp(file)
    plutocelllist = string.(split(plutoraw, _cell_id_delimiter))
    jupyterloadcell = parse_pluto_load(plutocelllist[1])
    i=2
    pcells = PlutoCell[]
    while(i <= length(plutocelllist)-1)
        pcell = parse_pluto_cell(plutocelllist[i])
        push!(pcells, pcell)
        i+=1
    end
    plutoend = parse_pluto_end(plutocelllist[end])
    ordered_pcells = order(pcells, plutoend)
    jcells = map( pcell -> JupyterCell(pcell), ordered_pcells)
    all_main_cells = Dict.(jcells)
    pushfirst!(all_main_cells, Dict(jupyterloadcell))
    d_cells = Dict()
    d_cells["cells"] = all_main_cells
    d_cells["metadata"] = Dict(
        "kernelspec"=> Dict(
            "display_name"=> "Julia $(VERSION)",
            "language"=> "julia",
            "name"=> "julia-$(VERSION.major).$(VERSION.minor)"
        ),
        "language_info"=> Dict(
            "file_extension"=> ".jl",
            "mimetype"=> "application/julia",
            "name"=> "julia",
            "version"=> string(VERSION)
        )
    )
    d_cells["nbformat"]= 4
    d_cells["nbformat_minor"]= 2
    dest = file*".ipynb"
    open(dest, "w") do f
        JSON.print(f, d_cells , 4)
    end
    dest

end
end # module
