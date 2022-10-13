
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
    pattern::OmnidirectionalPattern,
)::Real
    1
end


"""

"""
function directivity_pattern(
    d::SVector{3, <:Real},
    B::SMatrix{3, 3, <:Real},
    pattern::SubcardioidPattern,
)::Real
    cardioid_pattern(d, B, 0.75)
end


"""

"""
function directivity_pattern(
    d::SVector{3, <:Real},
    B::SMatrix{3, 3, <:Real},
    pattern::CardioidPattern,
)::Real
    cardioid_pattern(d, B, 0.50)
end


"""

"""
function directivity_pattern(
    d::SVector{3, <:Real},
    B::SMatrix{3, 3, <:Real},
    pattern::HypercardioidPattern,
)::Real
    cardioid_pattern(d, B, 0.25)
end


"""

"""
function directivity_pattern(
    d::SVector{3, <:Real},
    B::SMatrix{3, 3, <:Real},
    pattern::BidirectionalPattern,
)::Real
    cardioid_pattern(d, B, 0.00)
end
    
