include("splines.jl")
include("random.jl")

using Luxor, DelaunayTriangulation
import .Random as R
import .Splines as S

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

Given a set of points, generate a graph by connecting the points with edges
that are not the longest edge of a triangle in the Delaunay triangulation.
"""
function generate_graph(vertices)
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

"""
    get_endpoints(graph_edges)

Given a set of graph edges, return the vertices that are only part of one edge.
"""
function get_endpoints(graph_edges)
    vertex_count = Dict{Int, Int}()
    for edge in graph_edges
        vertex_count[edge.v1] = get(vertex_count, edge.v1, 0) + 1
        vertex_count[edge.v2] = get(vertex_count, edge.v2, 0) + 1    
    end

    endpoints = [k for (k, v) in vertex_count if v == 1]
    return endpoints
end

"""
    traverse_graph(graph_edges, endpoints)

Given a set of graph edges and a set of endpoints, traverse the graph starting
from one of the endpoints.
"""
function traverse_graph(graph_edges)
    endpoints = get_endpoints(graph_edges)

    if isempty(endpoints)
        println("No endpoints found!")
        return [], []
    end

    current_vertex = endpoints[rand(1:length(endpoints))]
    visited_edges = Set{Edge}()
    visited_vertices_set = Set{Int}()
    visited_vertices = Vector{Int}()
    push!(visited_vertices_set, current_vertex)

    while true
        next_edge = nothing
        for edge in filter(e -> ! (e in visited_edges), graph_edges)
            if edge.v1 == current_vertex || edge.v2 == current_vertex
                next_edge = edge
                break
            end
        end

        # If we can't find the next edge, we're done
        if next_edge === nothing
            break
        end

        # Otherwise, add the edge to the visited edges and move to the next vertex
        push!(visited_edges, next_edge)
        current_vertex = next_edge.v1 == current_vertex ? next_edge.v2 : next_edge.v1
        push!(visited_vertices_set, current_vertex)
        push!(visited_vertices, current_vertex)
    end

    return visited_edges, visited_vertices
end

function main()
    point_cloud = Random.distributed_pointcloud(12, 50, 20., 20., width - 40., height - 40.)
    vertices = map(pt2vert, point_cloud)
    graph_edges = generate_graph(vertices)
    traversed_edges, traversed_vertices = traverse_graph(graph_edges)
    traversed_points = map(vert2pt, map(v -> vertices[v], traversed_vertices))
    extended_points = [
        traversed_points[1] - (traversed_points[2] - traversed_points[1]),
        traversed_points...,
        traversed_points[end] + (traversed_points[end] - traversed_points[end-1])
    ]

    Drawing(width, height)
    background("white")
    setline(1)
    sethue("blue")
    S.catmullromspline(extended_points, 20)

    # for edge in graph_edges
    #     if edge in traversed_edges
    #         sethue("red")
    #     else
    #         sethue("black")
    #     end
    #     v1 = vertices[edge.v1]
    #     v2 = vertices[edge.v2]
    #     line(vert2pt(v1), vert2pt(v2))
    #     strokepath()
    #     circle(vert2pt(v1), 3, :fill)
    #     text(string(edge.v1), vert2pt(v1) + Point(10, 5))
    # end

    # for endpoint in endpoints
    #     sethue("red")
    #     circle(vert2pt(vertices[endpoint]), 3, :fill)
    #     text(string(endpoint), vert2pt(vertices[endpoint]) + Point(10, 5))
    # end

    finish()
    preview()
end

main()