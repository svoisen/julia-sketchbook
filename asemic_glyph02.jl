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
from one of the endpoints for n number of edges.
"""
function traverse_graph(graph_edges, total_edges=4)
    endpoints = get_endpoints(graph_edges)

    if isempty(endpoints)
        println("No endpoints found, removing edge")
        graph_edges = graph_edges[1:end-1]
        endpoints = get_endpoints(graph_edges)
    end

    current_vertex = endpoints[rand(1:length(endpoints))]

    # At the end of this, we want the order of edges and vertices visited
    # not just the set, but the set is useful for more efficient lookup
    visited_edges_set = Set{Edge}()
    visited_edges = Vector{Edge}()
    visited_vertices_set = Set{Int}()
    visited_vertices = Vector{Int}()
    push!(visited_vertices_set, current_vertex)

    num_edges = 0

    while num_edges < total_edges
        next_edge = nothing
        for edge in filter(e -> ! (e in visited_edges_set), graph_edges)
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
        push!(visited_edges_set, next_edge)
        push!(visited_edges, next_edge)
        num_edges += 1

        current_vertex = next_edge.v1 == current_vertex ? next_edge.v2 : next_edge.v1

        push!(visited_vertices_set, current_vertex)
        push!(visited_vertices, current_vertex)
    end

    return visited_edges, visited_vertices
end

function draw_stroke_linear(stroke)
    for i in 1:length(stroke) - 1
        line(vert2pt(stroke[i]), vert2pt(stroke[i + 1]))
        strokepath()
    end
end

function draw_stroke_spline(stroke)
    if length(stroke) < 3
        println("Not enough vertices to draw a spline!")
        return
    end

    points = map(vert2pt, stroke)
    extended_points = [
        points[1] - (points[2] - points[1]),
        points...,
        points[end] + (points[end] - points[end-1])
    ]
    S.catmullromspline(extended_points, 20)
end

"""
    draw_graph(graph_edges, vertices)

Debugging function to draw the graph edges and vertices.
"""
function draw_graph(graph_edges, vertices)
    sethue("black")
    for edge in graph_edges
        p1 = vert2pt(vertices[edge.v1])
        p2 = vert2pt(vertices[edge.v2])
        line(p1, p2)
        strokepath()
    end

    sethue("red")
    for vertex in vertices
        circle(vert2pt(vertex), 4, :fill)
    end
end

function draw_diacritical()
    p = randompoint(20., 20., width - 20., height - 20.)
    circle(p, 10)
    strokepath()
end

function main()
    point_cloud = Random.distributed_pointcloud(14, 50, 20., 20., width - 40., height - 40.)
    vertex_cloud = map(pt2vert, point_cloud)
    graph_edges = generate_graph(vertex_cloud)

    remaining_edges = copy(graph_edges)
    strokes = Vector{Vector{Int}}()

    # Traversal logic:
    # 1. Find the endpoints of the graph.
    # 2. Start at one of the endpoints.
    # 3. Traverse the graph by moving to the next edge that is connected to the current vertex. Perform a maximum
    #    of 2-4 edge traversals.
    # 4. Remove all traversed edges from the graph.
    # 4. If there are more endpoints to visit, repeat step 2.
    while(length(remaining_edges) > 0)
        traversed_edges, traversed_vertices = traverse_graph(remaining_edges, rand(2:5))
        # If we can't find any more traversals or vertices because there are no more endpoints, we're done
        if length(traversed_edges) == 0 || length(traversed_vertices) == 0
            break
        end

        push!(strokes, traversed_vertices)
        remaining_edges = setdiff(remaining_edges, traversed_edges)
    end

    vertex_strokes = map(stroke -> map(i -> vertex_cloud[i], stroke), strokes)

    Drawing(width, height)
    background("white")
    setline(1)

    draw_graph(graph_edges, vertex_cloud)

    sethue("blue")

    for stroke in vertex_strokes
        if rand() > 0.25
            draw_stroke_spline(stroke)
        else
            draw_stroke_linear(stroke)
        end
    end

    draw_diacritical()

    finish()
    preview()
end

main()