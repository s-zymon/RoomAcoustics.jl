export h2RT60, Sabine_RT60


"""

"""
function h2RT60(h::AbstractVector{<:Number}, Fs::Real)
    cs = cumsum(reverse(h.^2))
    edc = 10*log10.(reverse(cs./cs[end])) # energy decay curve

    ind = findfirst(edc .<= -60. )
    if ind == nothing 
        rt = length(h)/Fs 
    else
        rt = ind/Fs
    end
    rt, edc
end


"""
"""
function Sabine_RT60(T60, L::Tuple, c)
    # Compute volume of the room
    V = prod(L)

    # Compute surface of the room
    S = 2*(L[1]*L[2] + L[1]*L[3] + L[2]*L[3])

    #
    α = 24 * V * log(10)/(c * S * T60)

    #
    sqrt(1-α)
end



"""
b = [1, -B1, -B2]
a = [1, A1, R1] 
"""
function AllenBerkley_highpass100(x, fs)
    o = x .* 0
    Y = zeros(3)

    W = 2π*100/fs

    R1 = exp(-W)
    B1 = 2*R1*cos(W)
    B2 = -R1 * R1   
    A1 = -(1+R1)

    for i = 1:length(x)
        Y[3] = Y[2]
        Y[2] = Y[1]
        Y[1] = B2*Y[3] + B1*Y[2] + x[i]
        o[i] = Y[1] + A1*Y[2] + R1*Y[3]
    end

    return o
end
