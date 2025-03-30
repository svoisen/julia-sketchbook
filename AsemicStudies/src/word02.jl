"""
Word study using randomized glyphs by creating points in an ellipse
and connecting them with a B-spline.
"""

using Revise, Luxor, Plotline

function generate_glyph(origin::Point, width::Real, minheight::Real, maxheight::Real)
    b = (minheight + rand() * (maxheight - minheight)) / 2.0
    pts = distpointsinellipse(rand(4:8), origin, width / 2.0, b)
    return polyfit(Vector{Point}(pts), 30)
end

canvas_width = 400.0
canvas_height = 400.0

@draw begin
    origin()
    setline(1)
    sethue("black")

    glyph_width = 50.0
    min_glyph_height = 20.0
    max_glyph_height = 150.0

    points = Vector{Point}()
    for i in 0:4
        x = i * glyph_width + glyph_width / 2.0 - canvas_width / 2.0
        glyph = generate_glyph(Point(x, 0.0), glyph_width, min_glyph_height, max_glyph_height)
        global points = vcat(points, glyph)
    end

    poly(points, :stroke)
end