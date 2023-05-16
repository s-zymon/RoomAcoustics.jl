
export AbstractRoom, RectangularRoom
export AbstractRIRConfig, ISMConfig



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


