module QuadTree

export Rect, Point, QuadTreeNode, subdivide!, insert!

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

function contains(rect::Rect{T}, p::Point{T}) where T<:Real
    return contains(rect, p.x, p.y)
end

"""
    intersects(a::Rect{T}, b::Rect{T}) where T<:Real

Check if two rectangles intersect.
"""
function intersect(a::Rect{T}, b::Rect{T}) where T<:Real
    return !(a.x + a.width < b.x || a.y + a.height < b.y || 
             a.x > b.x + b.width || a.y > b.y + b.height)
end

mutable struct QuadTreeNode{T<:Real, D}
    boundary::Rect{T}
    capacity::Int
    data::Vector{D}
    children::Array{QuadTreeNode{T, D}}

    function QuadTreeNode(boundary::Rect{T}, capacity::Int, data::Vector{D}) where {T<:Real, D}
        new{T,D}(boundary, capacity, data, QuadTreeNode{T,D}[])
    end
end

function subdivide!(node::QuadTreeNode{T, D}) where {T<:Real, D}
    x = node.boundary.x
    y = node.boundary.y
    w = node.boundary.width
    h = node.boundary.height
    c = node.capacity

    nw = Rect(x, y, w/2, h/2)
    node.children = [QuadTreeNode(nw, c, Vector{D}())]

    ne = Rect(x + w/2, y, w/2, h/2)
    push!(node.children, QuadTreeNode(ne, c, Vector{D}()))

    sw = Rect(x, y + h/2, w/2, h/2)
    push!(node.children, QuadTreeNode(sw, c, Vector{D}()))

    se = Rect(x + w/2, y + h/2, w/2, h/2)
    push!(node.children, QuadTreeNode(se, c, Vector{D}()))

    # Move the data from the parent to the correct child
    for item in node.data
        for child in node.children
            if contains(child.boundary, item)
                push!(child.data, item)
                break
            end
        end
    end

    # Empty the parent data
    node.data = Vector{D}()
end

function insert!(node::QuadTreeNode{T, D}, data::D) where {T<:Real, D}
    if !contains(node.boundary, data)
        return
    end

    # If this is a leaf node
    if isempty(node.children)
        # If there is space in this node, add the data
        if length(node.data) < node.capacity
            push!(node.data, data)
        else
            # Otherwise, subdivide and insert the data into one of the children
            subdivide!(node)

            for child in node.children
                insert!(child, data)
            end
        end
    else
        # If this is not a leaf node, insert the data into one of the children
        for child in node.children
            insert!(child, data)
        end
    end
end

end