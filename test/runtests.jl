using CounterfactualExplanations
using CounterfactualExplanations.DataPreprocessing
using CounterfactualExplanations.Models
using LaplaceRedux
using Printf
using PythonCall
using Random
using TaijaData
using TaijaInteroperability
using Test

include("utils.jl")

synthetic = _load_synthetic()

@testset "TaijaInteroperability.jl" begin
    include("pytorch.jl")
end
