export  Omnidirectional,
        Subcardioid,
        Cardioid,
        Hypercardioid,
        Bidirectional

export TxRx, TxRxArray

export Room, RectangularRoom
export RIRConfig, ISMConfig




abstract type AbstractDirectivityPattern end
struct OmnidirectionalPattern <: AbstractDirectivityPattern end
struct SubcardioidPattern     <: AbstractDirectivityPattern end
struct CardioidPattern        <: AbstractDirectivityPattern end
struct HypercardioidPattern   <: AbstractDirectivityPattern end
struct BidirectionalPattern   <: AbstractDirectivityPattern end


const Omnidirectional = OmnidirectionalPattern()
const Subcardioid     = SubcardioidPattern()
const Cardioid        = CardioidPattern()
const Hypercardioid   = HypercardioidPattern()
const Bidirectional   = BidirectionalPattern()



abstract type AbstractTxRx end

struct TxRx{T<:Real} <: AbstractTxRx
    position::SVector{3, T}                 # Position
    B::SMatrix{3, 3, T}                     # Orientation
    directivity::AbstractDirectivityPattern # Directivity pattern
end

function TxRx(position, B=SMatrix{3,3}(1.0I), d=Omnidirectional)
    TxRx(position |> SVector{3}, B, d)
end

struct TxRxArray{T<:Real} <: AbstractTxRx
    p::Vector{<:TxRx{T}}    # list of TxRxes in the local frame
    origin::SVector{3, T}   # Position of the local origin in reference to the global origin
    B::SMatrix{3, 3, T}     # Orientation of the array (local -> global)
end


abstract type Room end

struct RectangularRoom{T<:Real} <: Room
    c::T
    L::Tuple{T, T, T}
    β::Tuple{T, T, T, T, T, T}
end



abstract type RIRConfig end

"""

"""
struct ISMConfig{T<:Real, I<:Integer, R<:AbstractRNG} <: RIRConfig
    order::Tuple{I, I}  # Order of reflection [low, high]
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


