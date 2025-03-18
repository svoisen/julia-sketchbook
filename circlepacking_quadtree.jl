import Luxor as L
import .QuadTree as Q

boundary = Q.Rect{Float64}(0.0, 0.0, 400.0, 400.0)
root = Q.QuadTreeNode(boundary, 20, Q.Point{Float64}[])
for _ in 1:100
    Q.insert!(root, Q.Point(rand(0.:400.), rand(0.:400.)))
end

function draw(node::Q.QuadTreeNode{T, D}) where {T<:Real, D}
    if isempty(node.children)
        L.sethue("black")
        L.setline(0.5)
        L.rect(node.boundary.x, node.boundary.y, node.boundary.width, node.boundary.height)
        L.strokepath()

        L.sethue("red")
        for point in node.data
            L.circle(point.x, point.y, 2, :fill)
        end
    else
        for child in node.children
            draw(child)
        end
    end
end

L.Drawing(400, 400)
L.background("white")
draw(root)
L.finish()
L.preview()