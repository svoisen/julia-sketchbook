include("splines.jl")

"""
Draw a single asemic character using a random plotting
of points and fitting a Catmull-Rom spline to the points.
"""

using Luxor
import ..Splines as S

width = 400.0
height = 400.0

points = [Point(rand(-width/2:width/2), rand(-height/2:height/2)) for _ in 1:5]
extended_points = [
    points[1] - (points[2] - points[1]),
    points...,
    points[end] + (points[end] - points[end-1])
]

Drawing(400, 400)
origin()
background("white")

sethue("red")
for (i, point) in enumerate(extended_points)
    circle(point, 5, :fill)
    text(string(i), point + Point(10, 5))
end

setline(2)
sethue("blue")
S.catmullromspline(extended_points, 20)

finish()
preview()