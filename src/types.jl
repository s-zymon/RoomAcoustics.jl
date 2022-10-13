export  Omnidirectional,
        Subcardioid,
        Cardioid,
        Hypercardioid,
        Bidirectional

export TxRx

export Room, RectangularRoom
export RIRConfig, ISMConfig




abstract type DirectivityPattern end
struct OmnidirectionalPattern <: DirectivityPattern end
struct SubcardioidPattern     <: DirectivityPattern end
struct CardioidPattern        <: DirectivityPattern end
struct HypercardioidPattern   <: DirectivityPattern end
struct BidirectionalPattern   <: DirectivityPattern end


const Omnidirectional = OmnidirectionalPattern()
const Subcardioid     = SubcardioidPattern()
const Cardioid        = CardioidPattern()
const Hypercardioid   = HypercardioidPattern()
const Bidirectional   = BidirectionalPattern()



struct TxRx{T<:AbstractFloat}
    position::SVector{3, T}            # Position
    B::SMatrix{3, 3, T}                # Orientation
    directivity::DirectivityPattern    # Directivity pattern
end

function TxRx(position, B=SMatrix{3,3}(1.0I), d=Omnidirectional)
    TxRx(position, B, d)
end


abstract type Room end

struct RectangularRoom{T<:AbstractFloat} <: Room
    c::T
    L::Tuple{T, T, T}
    β::Tuple{T, T, T, T, T, T}
end



abstract type RIRConfig end

"""

"""
struct ISMConfig{T<:AbstractFloat, I <: Integer} <: RIRConfig
    order::Tuple{I, I}  # Order of reflection [low, high]
    fs::T               # Sampling frequency
    N::I                # Number of samples in impulse response
    Wd::T               # Single impulse width
    hp::Bool            # High pass filter
    isd::T              # Image source distortion (randomized image method)
    lrng::AbstractRNG
end

function ISMConfig(
    order=(0, -1),
    fs=16000,
    N=4000,
    Wd=8e-3,
    hp=true,
    isd=0.0,
    lrng=GLOBAL_RNG
)
    ISMConfig(order, fs, N, Wd, hp, isd, lrng)
end


