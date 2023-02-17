module WASN

using LinearAlgebra
using DSP: conv

using TxRxModels

using ..RoomAcoustics: AbstractRoom, AbstractRIRConfig, ISM

export Node, Event
export synth_events

struct Node
    rx::TxRxArray
    fs::Real
    δ::Real
end

function Node(rx, δ=0.0)
    Node(rx, δ)
end

struct Event
    tx::TxRx
    emission::Real
    fs::Real
    signal::AbstractVector
end

function synth_events(
    nodes::AbstractVector{<:Node},
    events::AbstractVector{<:Event},
    room::AbstractRoom,
    rir_config::AbstractRIRConfig,
)
    hs = [ISM(nodes[i].rx, events[j].tx, room, rir_config) for i in eachindex(nodes), j in eachindex(events)]
    s = [[conv(h, events[j].signal) for h in hs[i, j]] for i in eachindex(nodes), j in eachindex(events)]

    (signals=s, hs=hs)
end

function synthesise(
    nodes::AbstractVector{<:Node},
    events::AbstractVector{<:Event},
    room::AbstractRoom,
    rir_config::AbstractRIRConfig,
)
    # WARN: THIS FUNCTION ASSUMES NOW THAT ALL sampling rates are the same.
    fs = first(nodes).fs

    # Synthesise individual events for given nodes
    e_signals, h_s = synth_events(nodes, events, room, rir_config)

    # Find length of the output signal
    δ_max = [node.δ for node ∈ nodes] |> maximum;
    N = [ceil(Int, (events[j].emission + δ_max)*fs) + length(e_signals[1, j][1]) for j ∈ eachindex(events)] |> maximum

    # Allocate memory for output signals
    output = [zeros(N, node.rx.p |> length) for node ∈ nodes]

    for i ∈ eachindex(nodes), j ∈ eachindex(events)
        shift_n = floor(Int, (events[j].emission + nodes[i].δ)*fs)
        event = e_signals[i,j]
        for (idx, channel) in enumerate(event)
            output[i][shift_n:shift_n+length(channel)-1, idx] .= channel
        end
    end

    return (
        node_output   = output,
        event_signals = e_signals,
        h             = h_s,
    )
end

end # module WASN
