using Documenter
#include("../src/QSWalk.jl")
using QSWalk

# same for contributing and license
cp(normpath(@__FILE__, "../../LICENSE"), normpath(@__FILE__, "../src/license.md"); force=true)



makedocs(
    modules     = [QSWalk],
    format      = Documenter.HTML(assets = ["assets/logo.ico"]),
    sitename    = "QSWalk",
    clean       = true,
    doctest     = true,
    checkdocs   = :exports,
    pages       = Any[
		"Home"				=> "index.md",
        "GKSL master equation" => "gksl.md",
    	"Demoralization"   => "demoralization.md",
        "Contributing"		=> "contributing.md",
        "Citing"	       	=> "citing.md",
		"Licence"			=> "license.md",
    ]
)

deploydocs(
    deps        = nothing,
    make        = nothing,
    repo        = "github.com/QuantumWalks/QSWalk.jl",
    target      = "build",
    julia       = "1.1",
    osname      = "linux"
)


#rm(normpath(@__FILE__, "src/license.md"))
