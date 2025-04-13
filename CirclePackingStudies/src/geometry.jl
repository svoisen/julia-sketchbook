module Geometry

export Rect, Point, Circle, contains, intersects, disttocircle

"""
    Rect{T<:Real}

Represents a rectangle with a top-left corner at (x, y) and a width and height.
"""
mutable struct Rect{T<:Real}
    x::T
    y::T
    width::T
    height::T
end

"""
    Point{T<:Real}

Represents a point with x and y coordinates.
"""
mutable struct Point{T<:Real}
    x::T
    y::T
end

"""
    Circle{T<:Real}

Represents a circle with a center at (x, y) and a radius.
"""
mutable struct Circle{T<:Real}
    center::Point{T}
    radius::T
end

"""
    contains(rect::Rect{T}, x::T, y::T) where T<:Real

Check if the point (x, y) is contained within the rectangle.
"""
function contains(rect::Rect{T}, x::T, y::T) where T<:Real
    return x >= rect.x && x <= rect.x + rect.width &&
           y >= rect.y && y <= rect.y + rect.height
end

"""
    contains(rect::Rect{T}, p::Point{T}) where T<:Real

Check if the point p is contained within the rectangle.
"""
function contains(rect::Rect{T}, p::Point{T}) where T<:Real
    return contains(rect, p.x, p.y)
end

function contains(rect::Rect{T}, circle::Circle{T}) where T<:Real
    return contains(rect, circle.center)
end

"""
    intersects(a::Rect{T}, b::Rect{T}) where T<:Real

Check if two rectangles intersect.
"""
function intersects(a::Rect{T}, b::Rect{T}) where T<:Real
    return !(a.x + a.width < b.x || a.y + a.height < b.y || 
             a.x > b.x + b.width || a.y > b.y + b.height)
end

"""
Check if a circle intersects a rectangle.
"""
function intersects(rect::Rect{T}, circle::Circle{T}) where T<:Real
    # Find the closest point on the rectangle to the center of the circle
    closest_x = max(rect.x, min(circle.center.x, rect.x + rect.width))
    closest_y = max(rect.y, min(circle.center.y, rect.y + rect.height))
    
    # Calculate the distance between the closest point and the center of the circle
    distance_x = circle.center.x - closest_x
    distance_y = circle.center.y - closest_y
    
    # If the distance is less than the radius, the circle and rectangle intersect
    distance_squared = distance_x^2 + distance_y^2
    return distance_squared <= circle.radius^2
end

function intersects(circle::Circle{T}, rect::Rect{T}) where T<:Real
    return intersects(rect, circle)
end


"""
    disttocircle(x::Float64, y::Float64, circle::Circle)

Calculate the distance of a point to a circle
"""
function disttocircle(x::Float64, y::Float64, circle::Circle)
    dx = x - circle.center.x
    dy = y - circle.center.y

    return sqrt(dx^2 + dy^2) - circle.radius
end

function disttocircle(p::Point{Float64}, circle::Circle{Float64})
    return disttocircle(p.x, p.y, circle)
end

end