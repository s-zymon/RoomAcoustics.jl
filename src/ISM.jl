export ISM

function ISM(
    tx::TxRx,
    rx_array::TxRxArray,
    room::AbstractRoom,
    config::ISMConfig;
)
    rxs, origin, B = rx_array.txrx, rx_array.origin, rx_array.B
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
        tx.directivity,  # transmitter directivity pattern
        tx.B,            # transmitter orientation
        rx.position,     # receiver position
        rx.directivity,  # receiver directivity pattern
        rx.B,            # receiver orientation
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
    tx_p::SVector{3,T},                 # transmitter position
    tx_dp::AbstractDirectivityPattern,  # transmitter directivity pattern
    tx_B::SMatrix{3,3,T},               # receiver orientation
    rx_p::SVector{3,T},                 # reveiver position
    rx_dp::AbstractDirectivityPattern,  # receiver directivity pattern
    rx_B::SMatrix{3,3,T},               # receiver orientation
    L::Tuple{T,T,T},                    # room size (Lx, Ly, Lz)
    β::Tuple{T,T,T,T,T,T},              # reflection coefficients (βx1, βx2, βy1, βy2, βz1, βz2)
    c::T,                               # velocity of the wave
    fs::T,                              # sampling frequeyncy
    order::Tuple{I,I},                  # order of reflections; (min, max)
    Nh::Integer,                        # number of returned samples
    Wd::T,                              # window width
    ISD::T,                             # random displacement of image source
    lrng::AbstractRNG                   # random number generator
)::AbstractVector{T} where {T<:AbstractFloat, I<:Integer}
    # Allocate memory for the impulose response
    h = zeros(T, Nh)

    # Call
    ISM_RectangularRoom_core!(
        h,      # container for impulse response
        tx_p,   # transmitter position
        tx_dp,  # transmitter directivity pattern
        tx_B,   # transmitter orientation
        rx_p,   # receiver position
        rx_dp,  # receiver directivity pattern
        rx_B,   # receiver orientation
        L,      # room size
        β,      # reflection coefficients
        c,      # velocity of the sound
        fs,     # sampling frequency
        order,  # order of reflections
        Wd,     # single impulse width
        ISD,    # random image source displacement
        lrng,   # Local random number generator
    )
    h
end

"""

References:
[1] J. B. Allen and D. A. Berkley, “Image method for efficiently simulating small‐room acoustics,” The Journal of the Acoustical Society of America, vol. 65, no. 4, Art. no. 4, Apr. 1979, doi: 10.1121/1.382599.
[2] P. M. Peterson, “Simulating the response of multiple microphones to a single acoustic source in a reverberant room,” The Journal of the Acoustical Society of America, vol. 80, no. 5, Art. no. 5, Nov. 1986, doi: 10.1121/1.394357.
[3] E. De Sena, N. Antonello, M. Moonen, and T. van Waterschoot, “On the Modeling of Rectangular Geometries in Room Acoustic Simulations,” IEEE/ACM Transactions on Audio, Speech, and Language Processing, vol. 23, no. 4, Art. no. 4, Apr. 2015, doi: 10.1109/TASLP.2015.2405476.
[4] F. Brinkmann, V. Erbes, and S. Weinzierl, “Extending the closed form image source model for source directivity,” presented at the DAGA 2018, Munich, Germany, Mar. 2018.
"""
function ISM_RectangularRoom_core!(
    h::AbstractVector{<:T},
    tx_p::SVector{3,T},                 # transmitter position
    tx_dp::AbstractDirectivityPattern,  # transmitter directivity pattern
    tx_B::SMatrix{3,3,T},               # receiver orientation
    rx_p::SVector{3,T},                 # reveiver position
    rx_dp::AbstractDirectivityPattern,  # receiver directivity pattern
    rx_B::SMatrix{3,3,T},               # receiver orientation
    L::Tuple{T,T,T},                    # room size (Lx, Ly, Lz)
    β::Tuple{T,T,T,T,T,T},              # Reflection coefficients (βx1, βx2, βy1, βy2, βz1, βz2)
    c::T,                               # velocity of the wave
    fs::T,                              # sampling frequeyncy
    order::Tuple{I,I},                  # order of reflections; min max
    Wd::T,                              # Window width
    ISD::T,                             # Random displacement of image source
    lrng::AbstractRNG;                  # random number generator
) where {T<:AbstractFloat, I<:Integer}

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
    rd = @MVector zeros(T, 3)     # Container for random displacement
    isp = @MVector zeros(T, 3)    # Container for relative image source position
    b = @MVector zeros(T, 6)      # Container for effective reflection coefficient
    rx_DoA = @MVector zeros(T, 3) # Container for direction of incoming ray to receiver
    tx_DoA = @MVector zeros(T, 3) # Container for direction of ray coming out from transmitter
    Rp = @MVector zeros(T, 3)     #

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
                    Rp[i] = (1 .- 2 * p[i]) * tx_p[i] - rx_p[i]
                end

                # image source position for given permutation
                isp .= Rp .+ Rr

                if ISD > 0.0 && o > 0
                    # generate random displacement for the image source
                    randn!(lrng, rd)
                    isp .+= rd .* ISD
                end

                # Distance between receiver and image source
                d = norm(isp)

                # Propagation time between receiver and image source
                τ = d / c

                if τ <= Nh / fs # Check if it still in transfer function rangΩ

                    # Compute value of reflection coefficients
                    b .= β .^ abs.((n - q, n, l - j, l, m - k, m))

                    # Direction of Arrival of ray incoming from image source to receiver
                    rx_DoA .= isp ./ d

                    # Compute receiver directivity gain
                    rx_DG = directivity_pattern(SVector{3}(rx_DoA), rx_B, rx_dp)

                    # Direction of Arrival of ray coming out from transmitter to wall
                    perm = (abs(n - q) + abs(n), abs(l - j) + abs(l), abs(m - k) + abs(m))
                    tx_DoA .= -rx_DoA .* (-1, -1, -1).^perm

                    # Compute transmitter directivity gain
                    tx_DG = directivity_pattern(SVector{3}(tx_DoA), tx_B, tx_dp)

                    # Compute attenuation coefficient
                    A = tx_DG * rx_DG * prod(b) / (4π * d)

                    # Compute range of samples in transfer function
                    i_s = max(ceil(Int, (τ - Wd / 2) * fs) + 1, 1)  # start
                    i_e = min(floor(Int, (τ + Wd / 2) * fs) + 1, Nh) # end

                    # Insert yet another impulse into transfer function
                    @turbo for i ∈ i_s:i_e
                        t = (i - 1) / fs - τ # time signature
                        w = 0.5 * (1.0 + cos(2π * t / Wd)) # Hann window
                        x = π * fs * t + eps()
                        h[i] += w * A * sin(x)/x
                    end
                end
            end
        end
    end
end
