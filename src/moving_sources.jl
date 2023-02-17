export synth_movement

"""
Experimental
"""
function synth_movement(
    rx_path::AbstractVector{SVector{3, T}},
    signal::AbstractVector{T},
    tx::TxRx{T},
    room::AbstractRoom,
    config::AbstractRIRConfig,
    W_max::Integer = 2^11,
) where {T<:Real}
    P, N = length(rx_path), length(signal)

    # Synthesise room impulse responses for given path
    rirs = [ISM(tx, TxRx(p), room, config) for p in rx_path]

    # Find synthesis parameters
    best = typemax(Int);
    W, L = 0, 0
    for WW = 1:W_max, LL = 1:W_max-1
        score = P*WW - LL*(P-1) - N;
        if abs(score) <= best
            best = abs(score);
            W, L = WW, LL
            best == 0 && break
        end
    end

    # Compute synthesis window
    w = sin.((1:W)*π/(W+1))

    # Allocate memory for auxiliary signals
    out = zeros(P*(W-L)+L)
    dout = zeros(P*(W-L)+L)

    # Synthesise
    for (i, h) = enumerate(rirs)
        sh = conv(h, signal)
        f_s = (i-1)*(W-L) + 1
        f_e = f_s + W - 1
        out[f_s:f_e] += w .* sh[f_s:f_e]
        dout[f_s:f_e] += w
    end
    out ./ dout
end

