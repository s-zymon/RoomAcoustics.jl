module RoomAcoustics

using LinearAlgebra
using StaticArrays
using Statistics
using DSP
using Random
using Random: GLOBAL_RNG

using TxRxModels
using TxRxModels: AbstractDirectivityPattern

include("types.jl")
include("utils.jl")
include("ISM.jl")
include("moving_sources.jl")

export WASN
include("WASN.jl")

end # module
