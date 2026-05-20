# Characterization pattern: in-process call via PyCall
# Covers: Python → Julia migrations
#
# The test harness lives in Julia (the target language), so characterization
# and new implementation tests share the same infrastructure.
# PyCall calls the actual Python legacy source directly — no wrapper needed.
# The same golden files are later used to verify the new Julia implementation.

using Test, JSON3, PyCall

# Point Python's module search path at the legacy source tree
pushfirst!(PyVector(pyimport("sys")."path"), joinpath(@__DIR__, "../../../legacy/src"))

const legacy = pyimport("compute")  # the actual legacy Python module

const GOLDEN = joinpath(@__DIR__, "golden", "compute_output.json")

@testset "characterize Python compute output" begin
    result = legacy.compute(x=1.0, n_steps=10)
    actual = Dict("output" => Float64(result))

    if !isfile(GOLDEN)  # first run: save the reference
        mkpath(dirname(GOLDEN))
        open(GOLDEN, "w") do f
            JSON3.write(f, actual)
        end
        return
    end

    expected = JSON3.read(read(GOLDEN, String))["output"]
    @test isapprox(actual["output"], expected; rtol=1e-6)
end
