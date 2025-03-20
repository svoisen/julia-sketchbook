module QuadTree

import ..Geometry as G

export QuadTreeNode, subdivide!, insert!, query, allleaves

mutable struct QuadTreeNode{T<:Real, D}
    boundary::G.Rect{T}
    capacity::Int
    data::Vector{D}
    children::Array{QuadTreeNode{T, D}}

    function QuadTreeNode(boundary::G.Rect{T}, capacity::Int, data::Vector{D}) where {T<:Real, D}
        new{T,D}(boundary, capacity, data, QuadTreeNode{T,D}[])
    end
end

function subdivide!(node::QuadTreeNode{T, D}) where {T<:Real, D}
    x = node.boundary.x
    y = node.boundary.y
    w = node.boundary.width
    h = node.boundary.height
    c = node.capacity

    nw = G.Rect(x, y, w/2, h/2)
    node.children = [QuadTreeNode(nw, c, Vector{D}())]

    ne = G.Rect(x + w/2, y, w/2, h/2)
    push!(node.children, QuadTreeNode(ne, c, Vector{D}()))

    sw = G.Rect(x, y + h/2, w/2, h/2)
    push!(node.children, QuadTreeNode(sw, c, Vector{D}()))

    se = G.Rect(x + w/2, y + h/2, w/2, h/2)
    push!(node.children, QuadTreeNode(se, c, Vector{D}()))

    # Move the data from the parent to the correct child
    for item in node.data
        for child in node.children
            if G.contains(child.boundary, item)
                push!(child.data, item)
                break
            end
        end
    end

    # Empty the parent data
    node.data = Vector{D}()
end

function insert!(node::QuadTreeNode{T, D}, data::D) where {T<:Real, D}
    if !G.contains(node.boundary, data)
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

"""
    query(node::QuadTreeNode{T, D}) where {T<:Real, D}

Find the leaf node that contains the given point.
"""
function query(node::QuadTreeNode{T, D}, x::T, y::T) where {T<:Real, D}
    if !G.contains(node.boundary, x, y)
        return nothing
    end

    if isempty(node.children)
        return node
    end

    for child in node.children
        result = query(child, x, y)
        if result !== nothing
            return result
        end
    end

    return nothing
end

"""
Find the leaf nodes that intersect with a circle.
"""
function query(node::QuadTreeNode{T, D}, circle::G.Circle{T}) where {T<:Real, D}
    nodes = Vector{QuadTreeNode{T, D}}()
    query(node, circle, nodes)

    return nodes
end

function query(node::QuadTreeNode{T, D}, circle::G.Circle{T}, results::Vector{QuadTreeNode{T, D}}) where {T<:Real, D}
    if !G.intersects(node.boundary, circle)
        return
    end
    
    if isempty(node.children)
        push!(results, node)
        return
    end

    for child in node.children
        query(child, circle, results)
    end
end

function allleaves(node::QuadTreeNode{T, D}) where {T<:Real, D}
    leaves = Vector{QuadTreeNode{T, D}}()
    
    # If this is a leaf node, add it to the result
    if isempty(node.children)
        push!(leaves, node)
    else
        # Otherwise, recursively collect leaves from all children
        for child in node.children
            append!(leaves, allleaves(child))
        end
    end
    
    return leaves
end

end