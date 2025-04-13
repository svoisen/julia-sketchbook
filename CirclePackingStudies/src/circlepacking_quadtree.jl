include("geometry.jl")
include("quadtree.jl")

import Luxor as L
import .Geometry as G
import .QuadTree as Q

"""
Use Mitchell’s best-candidate algorithm to generate k candidate random samples
and choose the one with the largest minimum distance to the existing samples.

Algorithm:

1. Choose k random points.
2. For each point, find the distance to the nearest circle.
3. Choose the point with the minimum distance.
4. From all k samples, choose the point with the largest minimum distance.
5. Place a circle at that point.
6. Repeat steps 1-5 until the circles fill the space.
"""

const WIDTH = 400.0
const MAXRADIUS = 40.0
const K = 100

boundary = G.Rect{Float64}(0.0, 0.0, WIDTH, WIDTH)
circles = Vector{G.Circle{Float64}}()
root = Q.QuadTreeNode(boundary, 8, circles)

"""
    generatecircle()

Generate a circle using Mitchell's best-candidate algorithm
"""
function generatecircle()
    bestx, besty, bestdist = rand() * WIDTH, rand() * WIDTH, 0.0

    for _ in 1:K
        x = rand() * WIDTH
        y = rand() * WIDTH
        distance = Inf
        valid = true

        testcircle = G.Circle(G.Point(x, y), MAXRADIUS * 2)
        nodes = Q.query(root, testcircle)
        # nodes = allleaves(root)
        circles = map(node -> node.data, nodes)
        circles = isempty(circles) ? G.Circle{Float64}[] : reduce(vcat, circles)

        # Perform a linear search to find the distance to the nearest circle
        for circle in circles
            d = G.disttocircle(x, y, circle)
            # If the point is in a circle it's invalid
            if d < 0.0
                valid = false
                break
            end

            if d < distance
                distance = d
            end
        end

        if valid && distance > bestdist
            bestx, besty, bestdist = x, y, distance
        end
    end

    return G.Circle(G.Point(bestx, besty), min(MAXRADIUS, bestdist))
end

for _ in 1:1000
    circle = generatecircle()
    Q.insert!(root, circle)
end

function draw(node::Q.QuadTreeNode{T, D}) where {T<:Real, D}
    if isempty(node.children)
        L.sethue("black")
        L.setline(0.5)
        L.rect(node.boundary.x, node.boundary.y, node.boundary.width, node.boundary.height)
        L.strokepath()

        L.sethue("red")
        for circle in node.data
            L.circle(circle.center.x, circle.center.y, circle.radius, :stroke)
        end
    else
        for child in node.children
            draw(child)
        end
    end
end

L.Drawing(WIDTH, WIDTH)
L.background("white")
draw(root)
L.finish()
L.preview()