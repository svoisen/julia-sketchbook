"""
Sentence study using the techniques from word03.jl and previous studies.
1. For each character in the alphabet, create a point cloud of random points in an ellipse.
1a. Optionally fit the points using a B-spline (but don't draw it).
2. Connect the points using a Catmull-Rom spline.
3. Draw the resulting lines and curves.
4. Repeat for each character in the word.

Variables to play with:
- min_glyph_width
- max_glyph_width
- min_glyph_height: Min height of the glyph.
- max_glyph_height: Max height of the glyph.
- polyfit: Whether to fit the points using a B-spline or not.
"""

using Luxor, Plotline

struct Glyph
    points::Vector{Point}
    width::Real
    diacritic::Vector{Point}
end

struct Word
    points::Vector{Point}
    diacritics::Vector{Vector{Point}}
    width::Real
end

function generate_glyph_pts(origin::Point, width::Real, minheight::Real, maxheight::Real, shouldpolyfit::Bool = true)
    b = (minheight + rand() * (maxheight - minheight)) / 2.0
    pts = distpointsinellipse(rand(3:6), origin, width / 2.0, b)

    if shouldpolyfit
        # Fit the points using a B-spline
        return polyfit(Vector{Point}(pts), 10)
    end

    return pts
end

function generate_diacritic(upper_y::Real, lower_y::Real)
    y = upper_y - 5
    return [
        Point(-10 + rand(-3:3), y),
        Point(-5, y - 5),
        Point(0, y - 10 + rand(-3:3)),
        Point(5, y - 5),
        Point(10 + rand(-3:3), y)
    ]
end

"""
    generate_random_word(origin::Point, length::Int, glyph_map::Dict{Char, Glyph})

Generate a random word using the given origin point and length.
The word is generated by randomly selecting characters from the alphabet
and creating a glyph for each character.
The glyphs are then concatenated to form the final word.
"""
function generate_random_word(origin::Point, length::Int, glyph_map::Dict{Char, Glyph})
    chars = rand('a':'z', length)
    xpos = origin.x
    points = Vector{Point}()
    diacritics = Vector{Vector{Point}}()

    for c in chars
        glyph = glyph_map[c]
        if !isempty(glyph.diacritic)
            push!(diacritics, map(p -> Point(p.x + xpos, p.y), glyph.diacritic))
        end
        points = vcat(points, map(p -> Point(p.x + xpos, p.y), glyph.points))
        xpos += glyph.width
    end

    return Word(points, diacritics, xpos - origin.x)
end

function create_glyph_map(width::Real = 50, minheight::Real = 20, maxheight::Real = 150)
    glyph_map = Dict{Char, Glyph}()
    for c in 'a':'z'
        points = generate_glyph_pts(O, 50, minheight, maxheight, true)
        min_y = minimum(p.y for p in points)
        max_y = maximum(p.y for p in points)
        glyph_map[c] = Glyph(
            points,
            width,
            rand() > 0.8 ? generate_diacritic(min_y, max_y) : Vector{Point}(),
        )
    end
    return glyph_map
end

canvas_height = 400.0
canvas_width = 800.0

@draw begin
    origin(0, canvas_height / 2)
    setline(1)
    sethue("black")

    min_glyph_width = 40.0
    max_glyph_width = 60.0
    min_glyph_height = 20.0
    max_glyph_height = 150.0
    space_width = 10.0

    glyph_map = create_glyph_map(50.0, min_glyph_height, max_glyph_height)

    xpos = 25.0
    for _ in 1:2
        word = generate_random_word(Point(xpos, 0), rand(2:8), glyph_map)
        poly(catmullromspline(word.points), :stroke) 
        for diacritic in word.diacritics
            poly(catmullromspline(diacritic), :stroke)
        end
        global xpos = xpos + word.width + space_width
    end

end canvas_width canvas_height