using Jupyter2Pluto
using Test
using JSON

const line_markdown = "The diameter of a"
const multi_markdown = """The diameter of a pizza is often stated on a menu so let's define a **formula** to calculate the area of a pizza given the diameter **d**.

We do this by writing a formula like this: `area(d) = pi * (d/2)^2`

Let's write that below:"""

const line_markdown_wrap = "md\"$line_markdown\""
const multiline_markdown_wrap = """md\"\"\"$multi_markdown\"\"\"
"""

function test_pluto_parser()
    multiline_markdown_str = "2ed4bb92-d45c-11ea-0b31-2d8e32ce7b44\n$multiline_markdown_wrap"
    line_markdown_str = "03664f5c-d45c-11ea-21b6-91cd647a07aa\n$line_markdown_wrap"

    pmark_line_cell = Jupyter2Pluto.parse_pluto_cell(line_markdown_str)
    pmark_multiline_cell = Jupyter2Pluto.parse_pluto_cell(multiline_markdown_str)
    @testset "parse pluto line markdown cell" begin
        @test pmark_line_cell.cell_id == Base.UUID("03664f5c-d45c-11ea-21b6-91cd647a07aa")
        @test pmark_line_cell.content == line_markdown
    end
    @testset "parse pluto multiline markdown cell" begin
        @test pmark_multiline_cell.cell_id == Base.UUID("2ed4bb92-d45c-11ea-0b31-2d8e32ce7b44")
        @test pmark_multiline_cell.content == multi_markdown
    end
    pcode_cell = Jupyter2Pluto.parse_pluto_cell("""14158eb0-d45c-11ea-088f-330e45412320
area(d) = pi * (d / 2)^2""")

    @testset "parse pluto code cell" begin
        @test pcode_cell.cell_id == Base.UUID("14158eb0-d45c-11ea-088f-330e45412320")
        @test pcode_cell.content == "area(d) = pi * (d / 2)^2"
    end
    orders = Jupyter2Pluto.parse_pluto_end("""Cell order:
# ╟─03664f5c-d45c-11ea-21b6-91cd647a07aa
# ╠═14158eb0-d45c-11ea-088f-330e45412320
# ╠═2ed4bb92-d45c-11ea-0b31-2d8e32ce7b44
# ╟─e5e0a0da-d45c-11ea-1042-e9b5d0654d4f
""")
    @testset "Pluto cell order" begin
        @test orders == ["03664f5c-d45c-11ea-21b6-91cd647a07aa",
                        "14158eb0-d45c-11ea-088f-330e45412320",
                        "2ed4bb92-d45c-11ea-0b31-2d8e32ce7b44",
                         "e5e0a0da-d45c-11ea-1042-e9b5d0654d4f"]
         @test Jupyter2Pluto.order(Jupyter2Pluto.PlutoCell[pmark_line_cell, pmark_multiline_cell, pcode_cell], orders) == [pmark_line_cell, pcode_cell, pmark_multiline_cell]
        @test Jupyter2Pluto.order(Jupyter2Pluto.PlutoCell[pmark_line_cell, pmark_multiline_cell, pcode_cell], reverse(orders)) == [pmark_multiline_cell, pcode_cell, pmark_line_cell]
    end
    jmark_line_cell = Jupyter2Pluto.JupyterCell(pmark_line_cell)
    jmark_multiline_cell = Jupyter2Pluto.JupyterCell(pmark_multiline_cell)
    jcodecell = Jupyter2Pluto.JupyterCell(pcode_cell)
    @testset "Pluto to jupyter conversion"  begin
        @test jmark_line_cell.content == line_markdown
        @test jmark_multiline_cell.content == multi_markdown
        @test jcodecell.content == ["area(d) = pi * (d / 2)^2"]
        @test jcodecell.execution_count != 0
    end
    @testset "Jupyter to dict"  begin
        jmark_line_dict = Dict(jmark_line_cell)
        @test jmark_line_dict["cell_type"] == "markdown"
        @test isempty(jmark_line_dict["metadata"])
        @test jmark_line_dict["source"] == [line_markdown*"\n"]

        jmark_multiline_dict = Dict(jmark_multiline_cell)
        @test jmark_multiline_dict["cell_type"] == "markdown"
        @test isempty(jmark_multiline_dict["metadata"])
        @test jmark_multiline_dict["source"] == string.(split(multi_markdown, "\n")).*"\n"

        jcode_dict = Dict(jcodecell)
        @test jcode_dict["cell_type"] == "code"
        @test isempty(jcode_dict["metadata"])
        @test jcode_dict["execution_count"] != 0
        @test jcode_dict["source"] == ["""area(d) = pi * (d / 2)^2\n"""]
    end
end

function test_pluto2jupyter()
    test_notebook = joinpath(@__DIR__, "Basic mathematics.jl")
    pluto2jupyter(test_notebook)
    notebook = JSON.parsefile(test_notebook*".ipynb")
    @testset "check converted " begin
        @test notebook["nbformat"] == 4
        @test notebook["nbformat_minor"] == 2
        @test notebook["metadata"]["kernelspec"]["display_name"] == "Julia $(VERSION)"
        @test notebook["metadata"]["kernelspec"]["language"] == "julia"
        @test notebook["metadata"]["kernelspec"]["name"] == "julia-$(VERSION.major).$(VERSION.minor)"
        @test notebook["metadata"]["language_info"]["file_extension"] == ".jl"
        @test notebook["metadata"]["language_info"]["mimetype"] == "application/julia"
        @test notebook["metadata"]["language_info"]["name"] == "julia"
        @test string(notebook["metadata"]["language_info"]["version"]) == string(VERSION)
        @test !isempty(notebook["cells"])
   end

end

function main()
    test_pluto_parser()
    test_pluto2jupyter()
end
main()
