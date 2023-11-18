# @INFO: there is no SIMD version for sinc (sinpi etc.)
# We need a sinc kernel that can be SIMD vectorized
# Below is a sinple comparision of accuracy between a few approaches
using GLMakie

pix(x) = π * x
sinc2(x) = x |> pix |> (x -> iszero(x) ? 1.0 : sin(x)/x)
sinc3(x) = x |> pix |> (x -> x + eps(x)) |> (x -> sin(x)/x)


fs = 480e3
Δt = 1 / fs
t = -0.5:Δt:0.5
y_sinc = t .|> sinc;
y_sinc2 = t .|> sinc2;
y_sinc3 = t .|> sinc3;


@show maximum(abs, y_sinc .- y_sinc2)
@show maximum(abs, y_sinc .- y_sinc3)

fig = Figure()
ax = Axis(fig[1, 1])
lines!(ax, t, abs.(y_sinc - y_sinc2) .|> log10; label="if sinc")
lines!(ax, t, abs.(y_sinc - y_sinc3) .|> log10; label="eps sinc")
ylims!(ax, -16, -12)
xlims!(ax, (t |> extrema)...)
axislegend(ax)
