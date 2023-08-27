module TxRxModels

using LinearAlgebra
using StaticArrays

export  directivity_pattern,
        Omnidirectional,
        Subcardioid,
        Cardioid,
        Hypercardioid,
        Bidirectional
export TxRx, TxRxArray
export uniform_circle, fibonacci_sphere
export linear_array, circular_array, spherical_array, physical_array


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

struct TxRx{T<:Real, D<:AbstractDirectivityPattern} <: AbstractTxRx
    position::SVector{3, T} # Position
    B::SMatrix{3, 3, T}     # Orientation
    directivity::D          # Directivity pattern
    noise::T                # Noise floor [dB]
end

function TxRx(
    position,
    orientation=SMatrix{3,3}(1.0I),
    directivity_pattern=Omnidirectional,
    noise = -Inf
)
    position = position |> SVector{3}
    orientation = orientation |> SMatrix{3, 3}
    TxRx(position, orientation, directivity_pattern, noise)
end

struct TxRxArray{T<:Real} <: AbstractTxRx
    txrx::Vector{<:TxRx{T}} # list of TxRxes in the local frame
    origin::SVector{3, T}   # Position of the local origin in reference to the global origin
    B::SMatrix{3, 3, T}     # Orientation of the array (local -> global)
end

function TxRxArray(
    txrx,
    origin=SVector{3}([0., 0., 0.]),
    orientation=SMatrix{3,3}(1.0I)
)
    origin = origin |> SVector{3}
    TxRxArray(txrx, origin, orientation)
end


"""

"""
function directivity_pattern(
    d::SVector{3, <:Real},
    txrx::TxRx,
)::Real
    directivity_pattern(d, txrx.B, txrx.directivity)
end


"""

"""
function cardioid_pattern(
    d::SVector{3, <:Real},
    B::SMatrix{3, 3, <:Real},
    ρ::Real,
)::Real
    r = [1., 0., 0.]
    ρ + (1-ρ) * r' * B' * d
end



"""

"""
function directivity_pattern(
    d::SVector{3, <:Real},
    B::SMatrix{3, 3, <:Real},
    ::OmnidirectionalPattern,
)::Real
    1
end


"""

"""
function directivity_pattern(
    d::SVector{3, <:Real},
    B::SMatrix{3, 3, <:Real},
    ::SubcardioidPattern,
)::Real
    cardioid_pattern(d, B, 0.75)
end


"""

"""
function directivity_pattern(
    d::SVector{3, <:Real},
    B::SMatrix{3, 3, <:Real},
    ::CardioidPattern,
)::Real
    cardioid_pattern(d, B, 0.50)
end


"""

"""
function directivity_pattern(
    d::SVector{3, <:Real},
    B::SMatrix{3, 3, <:Real},
    ::HypercardioidPattern,
)::Real
    cardioid_pattern(d, B, 0.25)
end


"""

"""
function directivity_pattern(
    d::SVector{3, <:Real},
    B::SMatrix{3, 3, <:Real},
    ::BidirectionalPattern,
)::Real
    cardioid_pattern(d, B, 0.00)
end



function uniform_circle(N::Integer)
    Δα = 2π / N
    [SVector{3}([cos(α), sin(α), 0]) for α ∈ 0:Δα:2π-Δα]
end

function fibonacci_sphere(N::Integer)
    function f(i, offset, up, N)
        y = i * offset - 1 + offset / 2
        r = sqrt(1 - y^2)
        ϕ = ((i + 1.0) % N) * up
        x = cos(ϕ) * r
        z = sin(ϕ) * r
        return SVector{3}([x, y, z])
    end
    offset = 2.0 / N
    up = π * (3.0 - √5.0)
    [f(i, offset, up, N) for i = 0:N-1]
end




function linear_array(N::Integer, L::Real)
    ΔL = L / (N - 1)
    L2 = L / 2
    [SVector{3}([x - L2, 0, 0]) for x ∈ 0.00:ΔL:(N-1)*ΔL]
end

function circular_array(N::Integer, r::Real)
    Δα = 2π / N
    [SVector{3}([r * cos(α), r * sin(α), 0]) for α ∈ 0:Δα:2π-Δα]
end

function spherical_array(N::Integer, r::Real)
    P = fibonacci_sphere(N)
    [SVector{3}(r .* p) for p in P]
end



physical_array = (
    matrix_voice = (
        cartesian = [
            SVector{3}([+0.00000, +0.00000, +0.00000]),
            SVector{3}([-0.03813, +0.00358, +0.00000]),
            SVector{3}([-0.02098, +0.03204, +0.00000]),
            SVector{3}([+0.01197, +0.03638, +0.00000]),
            SVector{3}([+0.03591, +0.01332, +0.00000]),
            SVector{3}([+0.03281, -0.01977, +0.00000]),
            SVector{3}([+0.00500, -0.03797, +0.00000]),
            SVector{3}([-0.02657, -0.02758, +0.00000]),
        ],
    ),
    respeaker_6mic = (
        cartesian = (
            SVector{3}([-0.02320, +0.04010, +0.00000]),
            SVector{3}([-0.04630, +0.00000, +0.00000]),
            SVector{3}([-0.02320, -0.04010, +0.00000]),
            SVector{3}([+0.02320, -0.04010, +0.00000]),
            SVector{3}([+0.04630, +0.00000, +0.00000]),
            SVector{3}([+0.02320, +0.04010, +0.00000]),
        ),
    ),
    em32 = let
        r = 0.042
        sph = [ # source: https://mhacoustics.com/sites/default/files/EigenmikeReleaseNotesV18.pdf
            #    r,   θ    φ
            SVector{3}([r,  69,   0]), # Channel 01
            SVector{3}([r,  90,  32]), # Channel 02
            SVector{3}([r, 111,   0]), # Channel 03
            SVector{3}([r,  90, 328]), # Channel 04
            SVector{3}([r,  32,   0]), # Channel 05
            SVector{3}([r,  55,  45]), # Channel 06
            SVector{3}([r,  90,  69]), # Channel 07
            SVector{3}([r, 125,  45]), # Channel 08
            SVector{3}([r, 148,   0]), # Channel 09
            SVector{3}([r, 125, 315]), # Channel 10
            SVector{3}([r,  90, 291]), # Channel 11
            SVector{3}([r,  55, 315]), # Channel 12
            SVector{3}([r,  21,  91]), # Channel 13
            SVector{3}([r,  58,  90]), # Channel 14
            SVector{3}([r, 121,  90]), # Channel 15
            SVector{3}([r, 159,  89]), # Channel 16
            SVector{3}([r,  69, 180]), # Channel 17
            SVector{3}([r,  90, 212]), # Channel 18
            SVector{3}([r, 111, 180]), # Channel 19
            SVector{3}([r,  90, 148]), # Channel 20
            SVector{3}([r,  32, 180]), # Channel 21
            SVector{3}([r,  55, 225]), # Channel 22
            SVector{3}([r,  90, 249]), # Channel 23
            SVector{3}([r, 125, 225]), # Channel 24
            SVector{3}([r, 148, 180]), # Channel 25
            SVector{3}([r, 125, 135]), # Channel 26
            SVector{3}([r,  90, 111]), # Channel 27
            SVector{3}([r,  55, 135]), # Channel 28
            SVector{3}([r,  21, 269]), # Channel 29
            SVector{3}([r,  58, 270]), # Channel 30
            SVector{3}([r, 122, 270]), # Channel 31
            SVector{3}([r, 159, 271]), # Channel 32
        ];
        d2r((r, θ, φ)) = (r, θ*π/180., φ*π/180.)
        s2c((r, θ, φ)) = (r*sin(θ)*cos(φ), r*sin(θ)*sin(φ), r*cos(θ))
        (cartesian = sph .|> d2r .|> s2c, spherical = sph)
    end,
    zylia_zm1 = let
        r = 0.049
        sph = [ # Source: SPARTA Array2SH v1.6.8 plug-in
            SVector{3}([r, +0.0000000000000000, +90.00000000000000]), # Channel 01
            SVector{3}([r, +0.1752158999443054, +48.14300537109375]), # Channel 02
            SVector{3}([r, +120.09252166748050, +48.13568878173828]), # Channel 03
            SVector{3}([r, -119.94072723388670, +48.17926788330078]), # Channel 04
            SVector{3}([r, -82.167846679687500, +19.42138671875000]), # Channel 05
            SVector{3}([r, -37.613956451416020, +19.43202972412109]), # Channel 06
            SVector{3}([r, +37.885848999023440, +19.41517066955566]), # Channel 07
            SVector{3}([r, +82.290664672851560, +19.42664337158203]), # Channel 08
            SVector{3}([r, +157.87617492675780, +19.43287277221680]), # Channel 09
            SVector{3}([r, -157.59960937500000, +19.43940162658691]), # Channel 10
            SVector{3}([r, -142.11413574218750, -19.41517066955566]), # Channel 11
            SVector{3}([r, -97.709327697753910, -19.42664337158203]), # Channel 12
            SVector{3}([r, -22.123807907104490, -19.43287277221680]), # Channel 13
            SVector{3}([r, +22.400377273559570, -19.43940162658691]), # Channel 14
            SVector{3}([r, +97.832138061523440, -19.42138671875000]), # Channel 15
            SVector{3}([r, +142.38603210449220, -19.43202972412109]), # Channel 16
            SVector{3}([r, -179.82476806640620, -48.14300537109375]), # Channel 17
            SVector{3}([r, -59.907478332519530, -48.13568878173828]), # Channel 18
            SVector{3}([r, +60.059268951416020, -48.17926788330078]), # Channel 19
        ];
        d2r((r, θ, φ)) = SVector{3}([r, (θ+180)*π/180., (φ-90)*π/180.])
        s2c((r, φ, θ)) = SVector{3}([r*sin(θ)*cos(φ), r*sin(θ)*sin(φ), r*cos(θ)])
        (cartesian = sph .|> d2r .|> s2c, spherical = sph)
    end
);

end # module TxRxModels
