# RoomAcoustics.jl

`RoomAcoustics.jl` is a Julia package for acoustics simulations of the rooms.


```julia
] add https://codeberg.org/zymon/RoomAcoustics.jl
```


Currently, supported methods:
* Image Source for rectangular (shoebox) rooms


# Example

```julia
using StaticArrays
using LinearAlgebra

using RoomAcoustics


c = 343.0;
fs = 16000.0;
rir_Nsamples = 4000;
β = 0.75;
room_β = (β, β, β, β, β, β);
room_L = (10., 10., 3.);


mic = SVector{3}([5., 5., 1.]);
source = SVector{3}([1., 9., 2.]);


# Setup configuration
room = RectangularRoom(c, room_L, room_β);
rir_config = ISMConfig((0, -1), fs, rir_Nsamples, 8e-3, true, 0.0);
rx = TxRx(mic);
tx = TxRx(source);

# Compute transfer function using Image Source Method
h = ISM(rx, tx, room, rir_config);


```
