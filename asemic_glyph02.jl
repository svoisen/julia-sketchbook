include("splines.jl")

using Luxor, DelaunayTriangulation

width = 400.0
height = 400.0

struct Edge
    v1::Int
    v2::Int

    function Edge(a::Int, b::Int)
        a <= b ? new(a, b) : new(b, a)
    end
end

Base.hash(e::Edge, h::UInt) = hash((e.v1, e.v2), h)
Base.:(==)(a::Edge, b::Edge) = a.v1 == b.v1 && a.v2 == b.v2
Base.show(io::IO, e::Edge) = print(io, "Edge($(e.v1), $(e.v2))")

# The DelaunayTriangulation library uses a different representation of points
# and points than Luxor. The following functions convert between the two.
# We will call a vertex a point that is part of a Delaunay triangulation.
# We will use "point" to refer to a point in Luxor.
pt2vert(p) = (p.x, p.y)
vert2pt(v) = Point(v[1], v[2])
edge2pts(e) = (vert2pt(e[1]), vert2pt(e[2]))

points = [Luxor.randompoint(Point(0., 0), Point(width, height)) for _ in 1:12]
vertices = map(pt2vert, points)
triangulation = DelaunayTriangulation.triangulate(vertices)

"""
    edgelength(e::Edge)

Calculate the length of a graph edge assuming the edge is in the form of a tuple
of a tuple of two vertices.
"""
function edgelength(e::Edge, vertices::Vector)
    v1 = vertices[e.v1]
    v2 = vertices[e.v2]
    return sqrt((v1[1] - v2[1])^2 + (v1[2] - v2[2])^2)
end

"""
    generate_graph(points)

Given a set of points, generate a graph by connecting the points with edges
that are not the longest edge of a triangle in the Delaunay triangulation.
"""
function generate_graph(points)
    vertices = map(pt2vert, points)
    triangulation = DelaunayTriangulation.triangulate(vertices)
    longest_edges = Vector{Edge}()
    short_edges = Vector{Edge}() 

    for tri in each_solid_triangle(triangulation)
        triangle_edges = [Edge(tri[1], tri[2]), Edge(tri[2], tri[3]), Edge(tri[3], tri[1])]
        longest_edge_idx = argmax([edgelength(e, vertices) for e in triangle_edges])
        push!(longest_edges, triangle_edges[longest_edge_idx])

        for i in 1:3
            if i != longest_edge_idx
                push!(short_edges, triangle_edges[i])
            end
        end
    end

    graph_edges = setdiff(short_edges, longest_edges)
    return graph_edges
end

function main()
    Drawing(width, height)
    background("white")
    setline(1)

    for edge in generate_graph(points)
        sethue("black")
        v1 = vertices[edge.v1]
        v2 = vertices[edge.v2]
        line(vert2pt(v1), vert2pt(v2))
        strokepath()
    end

    finish()
    preview()
end

main()