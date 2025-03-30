"""
Generate an asemic glyph using using the following technique:
1. Generate a point cloud of random points in a circle.
2. Connect the points randomly using a BSpline.
3. Draw the resulting lines and curves.
"""

using Luxor, Plotline

@draw begin
    origin()
    sethue("black")
    setline(1)

    points = distpointsincircle(8, O, 200.)
    for p in points
        circle(p, 2, :fill)
    end
    poly(polyfit(Vector{Point}(points), 30), :stroke)
end