export ISM

function ISM(
    tx::TxRx,
    array::TxRxArray,
    room::AbstractRoom,
    config::ISMConfig;
)
    rxs, origin, B = array.txrx, array.origin, array.B
    l2g = rx -> TxRx(B * rx.position + origin, B * rx.B, rx.directivity)
    [ISM(tx, rx |> l2g, room, config) for rx in rxs]
end



"""

"""
function ISM(
    tx::TxRx,
    rxs::AbstractVector{<:TxRx},
    room::AbstractRoom,
    config::ISMConfig;
)
    [ISM(rx, tx, room, config) for rx in rxs]
end



"""

"""
function ISM(
    tx::TxRx,
    rx::TxRx,
    room::RectangularRoom,
    config::ISMConfig;
)
    h = ISM_RectangularRoom_core(
        tx.position,     # transmitter position
        rx.position,     # receiver position
        rx.B,            # receiver orientation
        rx.directivity,  # receiver directivity pattern
        room.L,          # room size
        room.β,          # reflection coefficients
        room.c,          # velocity of the sound
        config.fs,       # sampling frequency
        config.order,    # order of reflections
        config.N,        # length of response
        config.Wd,       # single impulse width
        config.isd,      # random image source displacement
        config.lrng,     # Local random number generator
    )

    if config.hp
        return AllenBerkley_highpass100(h, config.fs)
        # TODO: Zmień to na funkcie operującą na zaalokowanym już h
        # AllenBerkley_highpass100!(h, config.fs)
        # return h
    else
        return h
    end
end



"""

"""
function ISM_RectangularRoom_core(
    tx::SVector{3,T},                  # transmitter position
    rx::SVector{3,T},                  # reveiver position
    B::SMatrix{3,3,T},                # receiver orientation
    dp::AbstractDirectivityPattern,     # Receiver directivity pattern
    L::Tuple{T,T,T},                  # room size (Lx, Ly, Lz)
    β::Tuple{T,T,T,T,T,T},         # Reflection coefficients (βx1, βx2, βy1, βy2, βz1, βz2)
    c::T,                               # velocity of the wave
    fs::T,                              # sampling frequeyncy
    order::Tuple{<:Int,<:Int},         # order of reflections; min max
    Nh::Integer,                        # h lenght in samples
    Wd::T,                              # Window width
    ISD::T,                             # Random displacement of image source
    lrng::AbstractRNG                   # random number generator
)::AbstractVector{T} where {T<:AbstractFloat}

    # Allocate memory for the impulose response
    h = zeros(T, Nh)

    # Call
    ISM_RectangularRoom_core!(
        h,      # Container for impulse response
        tx,     # transmitter position
        rx,     # receiver position
        B,      # receiver orientation
        dp,     # receiver directivity pattern
        L,      # room size
        β,      # reflection coefficients
        c,      # velocity of the sound
        fs,     # sampling frequency
        order,  # order of reflections
        Wd,     # single impulse width
        ISD,    # random image source displacement
        lrng,   # Local random number generator
    )

    return h
end

"""

"""
function ISM_RectangularRoom_core!(
    h::AbstractVector{<:T},
    tx::SVector{3,T},                  # transmitter position
    rx::SVector{3,T},                  # reveiver position
    B::SMatrix{3,3,T},                # receiver orientation
    dp::AbstractDirectivityPattern,     # Receiver directivity pattern
    L::Tuple{T,T,T},                  # room size (Lx, Ly, Lz)
    β::Tuple{T,T,T,T,T,T},         # Reflection coefficients (βx1, βx2, βy1, βy2, βz1, βz2)
    c::T,                               # velocity of the wave
    fs::T,                              # sampling frequeyncy
    order::Tuple{<:Int,<:Int},         # order of reflections; min max
    Wd::T,                              # Window width
    ISD::T,                             # Random displacement of image source
    lrng::AbstractRNG                   # random number generator
)::AbstractVector{T} where {T<:AbstractFloat}

    # Number of samples in impulose response
    Nh = length(h)

    # Samples to distance coefficient [m]
    Γ = c / fs

    # Transform size of the room from meters to samples
    Lₛ = L ./ Γ

    # Compute maximal wall reflection
    N = ceil.(Int, Nh ./ (2 .* Lₛ))

    o_min, o_max = order

    # Allocate memory
    rd = @MVector zeros(T, 3)       # Container for random displacement
    tx_isp = @MVector zeros(T, 3)   # Container for relative image source position
    b = @MVector zeros(T, 6)        # Container for effective reflection coefficient
    DoA = @MVector zeros(T, 3)      # Container for direction of incoming ray to receiver
    Rp = @MVector zeros(T, 3)       # 

    # Main loop
    for n = -N[1]:N[1], l = -N[2]:N[2], m = -N[3]:N[3]
        r = (n, l, m)       # Wall reflection indicator
        Rr = 2 .* r .* L    # Wall lattice
        for q ∈ 0:1, j ∈ 0:1, k ∈ 0:1
            p = @SVector [q, j, k] # Permutation tuple

            # Order of reflection generated by image source
            o = sum(abs.(2 .* r .- p))

            if o_min <= o && (o <= o_max || o_max == -1)
                # Compute Rp part
                for i = 1:3
                    Rp[i] = (1 .- 2 * p[i]) * tx[i] - rx[i]
                end

                # Position of [randomized] image source for given permutation
                tx_isp .= Rp .+ Rr

                if ISD > 0.0 && o > 0
                    # Generate random displacement for the image source
                    randn!(lrng, rd)
                    tx_isp .+= rd .* ISD
                end

                # Distance between receiver and image source
                dist = norm(tx_isp)

                # Propagation time between receiver and image source
                τ = dist / c

                if τ <= Nh / fs # Check if it still in transfer function range

                    # Compute value of reflection coefficients
                    b .= β .^ abs.((n - q, n, l - j, l, m - k, m))

                    # Direction of Arrival of ray
                    DoA .= tx_isp ./ dist

                    # Compute receiver directivity gain
                    DG = directivity_pattern(SVector{3}(DoA), B, dp)

                    # Compute attenuation coefficient
                    A = DG * prod(b) / (4π * dist)

                    # Compute range of samples in transfer function
                    i_s = max(ceil(Int, (τ - Wd / 2) * fs) + 1, 1)  # start
                    i_e = min(floor(Int, (τ + Wd / 2) * fs) + 1, Nh) # end

                    # Insert yet another impulse into transfer function
                    for i ∈ i_s:i_e
                        t = (i - 1) / fs - τ # time signature
                        w = 0.5 * (1.0 + cos(2π * t / Wd)) # Hann window
                        h[i] += w * A * sinc(fs * t) # sinc
                    end
                end
            end
        end
    end
    h
end
