include("splines.jl")

using Luxor, DelaunayTriangulation

width = 400.0
height = 400.0

pt2vert(p) = (p.x, p.y)
vert2pt(v) = Point(v[1], v[2])
edge2pts(e) = (vert2pt(e[1]), vert2pt(e[2]))

points = [Luxor.randompoint(Point(0., 0), Point(width, height)) for _ in 1:8]
vertices = map(pt2vert, points)
triangulation = DelaunayTriangulation.triangulate(vertices)

Drawing(width, height)
background("white")
setline(1)

longest_edges = []

for t in each_solid_triangle(triangulation)
    len(e) = (e[1][1] - e[2][1])^2 + (e[1][2] - e[2][2])^2
    v1 = vertices[t[1]]
    v2 = vertices[t[2]]
    v3 = vertices[t[3]]
    edges = [(t[1], t[2]), (t[2], t[3]), (t[3], t[1])]
    vert_edges = [(v1, v2), (v2, v3), (v3, v1)]
    longest = argmax(map(len, vert_edges))
    push!(longest_edges, edges[longest])
end

for t in each_solid_triangle(triangulation)
    v1 = vertices[t[1]]
    v2 = vertices[t[2]]
    v3 = vertices[t[3]]
    edges = [(t[1], t[2]), (t[2], t[3]), (t[3], t[1])]
    mirror(edge) = (edge[2], edge[1])
    edges = filter(e -> !(e in longest_edges) && !(mirror(e) in longest_edges), edges)
    for e in edges
        println(e[1], " ", e[2])
        sethue("black")
        line(vert2pt(vertices[e[1]]), vert2pt(vertices[e[2]]))
        strokepath()
    end
end

finish()
preview()