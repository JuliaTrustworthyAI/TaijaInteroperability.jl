using TaijaInteroperability
using Documenter

DocMeta.setdocmeta!(TaijaInteroperability, :DocTestSetup, :(using TaijaInteroperability); recursive=true)

makedocs(;
    modules=[TaijaInteroperability],
    authors="Patrick Altmeyer",
    repo="https://github.com/JuliaTrustworthyAI/TaijaInteroperability.jl/blob/{commit}{path}#{line}",
    sitename="TaijaInteroperability.jl",
    format=Documenter.HTML(;
        prettyurls=get(ENV, "CI", "false") == "true",
        canonical="https://JuliaTrustworthyAI.github.io/TaijaInteroperability.jl",
        edit_link="master",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
    ],
)

deploydocs(;
    repo="github.com/JuliaTrustworthyAI/TaijaInteroperability.jl",
    devbranch="master",
)
