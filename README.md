# RoomAcoustics.jl

`RoomAcoustics.jl` is a Julia package for acoustics simulations of the rooms.


```julia
] add RoomAcoustics
```


Currently, supported methods:
* Fast Image Source method for rectangular (shoebox) rooms
* Transmitter and receiver directivity pattern support


# Example

```julia
using RoomAcoustics
using RoomAcoustics.TxRxModels

sampling_rate = 16e3
c = 343.0 # Wave propagation velocity

room = let
    L = (10.0, 5.0, 3.0)
    β = fill(0.55, 6) |> Tuple
    RectangularRoom(c, L, β)
end

rir_config = let
    h_len = convert(Int, sampling_rate * 0.50)
    ISMConfig((0, -1), sampling_rate, h_len)
end

rx = [2.2, 4.1, 1.6] |> TxRx
tx = [2.2, 4.1, 1.7] |> TxRx

h = ISM(tx, rx, room, rir_config)
```
