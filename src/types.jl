
export AbstractRoom, RectangularRoom
export AbstractRIRConfig, ISMConfig
export Node, Event


abstract type AbstractRoom end

struct RectangularRoom{T<:Real} <: AbstractRoom
    c::T
    L::Tuple{T,T,T}
    β::Tuple{T,T,T,T,T,T}
end



abstract type AbstractRIRConfig end

"""

"""
struct ISMConfig{T<:Real,I<:Integer,R<:AbstractRNG} <: AbstractRIRConfig
    order::Tuple{I,I}  # Order of reflection [low, high]
    fs::T               # Sampling frequency
    N::I                # Number of samples in impulse response
    Wd::T               # Single impulse width
    hp::Bool            # High pass filter
    isd::T              # Image source distortion (randomized image method)
    lrng::R
end

function ISMConfig(
    order=(0, -1),
    fs=16000.0,
    N=4000,
    Wd=8e-3,
    hp=true,
    isd=0.0,
    lrng=GLOBAL_RNG
)
    ISMConfig(order, fs, N, Wd, hp, isd, lrng)
end


struct Node{T<:Real}
    rx::TxRxArray{T}
    fs::T
    δ::T
    function Node(rx, fs::T, δ::T = 0.0) where T
        δ < 0.0 && error("δ < 0")
        fs < 0.0 && error("fs < 0")
        new{T}(rx, fs, δ)
    end
end

struct Event{T<:Real, V<:AbstractVector{<:T}} # NOTE: TxNode może będzie lepszą nazwa?
    tx::TxRx{T}
    emission::T
    fs::T
    signal::V
    function Event(tx, emission::T, fs::T, signal::V) where {T, V}
        emission < 0.0 && error("emission < 0")
        fs < 0.0 && error("fs < 0")
        new{T, V}(tx, emission, fs, signal)
    end
end
