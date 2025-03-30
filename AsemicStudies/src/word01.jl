using Luxor, Plotline

function generate_glyph(origin::Point, width::Real)
    pts = distpointsincircle(rand(4:8), origin, width / 2.0)
    return polyfit(Vector{Point}(pts), 30)
end

canvas_width = 400.0
canvas_height = 400.0

@draw begin
    origin()
    setline(1)
    sethue("black")

    glyph_width = 50.0

    points = Vector{Point}()
    for i in 0:4
        glyph = generate_glyph(Point(i * glyph_width + glyph_width / 2.0 - canvas_width / 2.0, 0), glyph_width)
        global points = vcat(points, glyph)
    end

    poly(points, :stroke)
end canvas_width canvas_height