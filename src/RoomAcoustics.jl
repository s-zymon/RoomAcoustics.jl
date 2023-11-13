module RoomAcoustics

using LinearAlgebra
using StaticArrays
using Statistics
using Random
using Random: GLOBAL_RNG

using LoopVectorization
using DSP: conv

include("TxRxModels.jl")
export TxRxModels
using .TxRxModels
using .TxRxModels:
    AbstractDirectivityPattern,
    AbstractTxRx

include("types.jl")
include("utils.jl")
include("ISM.jl")
include("moving_sources.jl")
include("node_event.jl")

end # module
