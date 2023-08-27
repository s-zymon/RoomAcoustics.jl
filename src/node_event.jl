
export synthesise_events4nodes, synthesise

function synthesise_events4nodes(
    nodes::AbstractVector{<:Node},
    events::AbstractVector{<:Event},
    room::AbstractRoom,
    rir_config::AbstractRIRConfig,
)
    hs = Matrix{Vector{Vector{Float64}}}(undef, nodes |> length, events |> length)
    s = Matrix{Vector{Vector{Float64}}}(undef, nodes |> length, events |> length)
    iter = Iterators.product(nodes |> eachindex, events |> eachindex) |> collect
    for (i,j) ∈ iter
        hs[i,j] = ISM(events[j].tx, nodes[i].rx, room, rir_config)
        s[i,j] = [conv(h, events[j].signal) for h in hs[i, j]]
    end
    return (
        signals=s,
        hs=hs
    )
end

function synthesise(
    nodes::AbstractVector{<:Node},
    events::AbstractVector{<:Event},
    room::AbstractRoom,
    rir_config::AbstractRIRConfig;
    pad::Real = 0.0
)
    # WARN: AT THIS MOMENT THIS FUNCTION ASSUMES THAT ALL sampling rates are the same.
    fs = first(nodes).fs

    # Synthesise individual events for ech node
    nodes_events, h = synthesise_events4nodes(nodes, events, room, rir_config)

    # Compute length of the output signal
    δ_max = [node.δ for node ∈ nodes] |> maximum;
    N = [ceil(Int, (events[j].emission + δ_max)*fs) + length(nodes_events[1, j][1]) for j ∈ eachindex(events)] |> maximum
    N += floor(Int, pad*fs)

    # Allocate memory for output signals
    output = [zeros(N, node.rx.txrx |> length) for node ∈ nodes]

    for i ∈ eachindex(nodes), j ∈ eachindex(events)
        shift_n = floor(Int, (events[j].emission + nodes[i].δ)*fs)+1
        event = nodes_events[i,j]
        for (idx, channel) in enumerate(event)
            output[i][shift_n:shift_n+length(channel)-1, idx] .+= channel
        end
    end

    return (
        node   = output,
        event  = nodes_events,
        h      = h,
    )
end
