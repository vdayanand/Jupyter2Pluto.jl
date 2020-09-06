using Test
using JSON
using Random
import Jupyter2Pluto: PlutoCell, JupyterMarkdownCell, JupyterCodeCell, generate_code

const markdown_arr = [
    "# Data structures\n",
    "\n",
    "Once we start working with many pieces of data at once, it will be convenient for us to store data in structures like arrays or dictionaries (rather than just relying on variables).<br>\n",
    "\n",
    "Types of data structures covered:\n",
    "1. Tuples\n",
    "2. Dictionaries\n",
    "3. Arrays\n",
    "\n",
    "<br>\n",
    "As an overview, tuples and arrays are both ordered sequences of elements (so we can index into them). Dictionaries and arrays are both mutable.\n",
    "We'll explain this more below!"
]

##TODO: fix remove \n from the last jupyter cell
const code_arr = ["# First, restore fibonacci\n", "fibonacci[1] = 1\n", "fibonacci"]
Random.seed!(1234)

function test_jupyter2pluto()
    #@info join(markdown_arr)
    jmark_cell = JupyterMarkdownCell(join(markdown_arr))
    pmc = PlutoCell(jmark_cell)
    @testset "test pluto markdown codegen" begin
        @test string(pmc) == """# ╔═╡ 196f2941-2d58-45ba-9f13-43a2532b2fa8
md\"\"\"
# Data structures

Once we start working with many pieces of data at once, it will be convenient for us to store data in structures like arrays or dictionaries (rather than just relying on variables).<br>

Types of data structures covered:
1. Tuples
2. Dictionaries
3. Arrays

<br>
As an overview, tuples and arrays are both ordered sequences of elements (so we can index into them). Dictionaries and arrays are both mutable.
We'll explain this more below!\"\"\"

"""
    end
    pcc = PlutoCell(JupyterCodeCell(1, code_arr))
    @testset "Pluto code block codegen" begin
        @test string(pcc) == """# ╔═╡ bd85187e-0531-4a3e-9fea-713204a818a2
begin
    # First, restore fibonacci
    fibonacci[1] = 1
    fibonacci
end

"""
    end
    @test string(generate_code(PlutoCell[pmc, pcc])) == """### A Pluto.jl notebook ###

# ╔═╡ 196f2941-2d58-45ba-9f13-43a2532b2fa8
md\"\"\"
# Data structures

Once we start working with many pieces of data at once, it will be convenient for us to store data in structures like arrays or dictionaries (rather than just relying on variables).<br>

Types of data structures covered:
1. Tuples
2. Dictionaries
3. Arrays

<br>
As an overview, tuples and arrays are both ordered sequences of elements (so we can index into them). Dictionaries and arrays are both mutable.
We'll explain this more below!\"\"\"

# ╔═╡ bd85187e-0531-4a3e-9fea-713204a818a2
begin
    # First, restore fibonacci
    fibonacci[1] = 1
    fibonacci
end

# ╔═╡ Cell order:
# ╟─196f2941-2d58-45ba-9f13-43a2532b2fa8
# ╠═bd85187e-0531-4a3e-9fea-713204a818a2
"""
end

test_jupyter2pluto()
