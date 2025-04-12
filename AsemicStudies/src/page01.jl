using Luxor, Plotline

struct DiacriticMark
    points::Vector{Vector{Point}}
    width::Real
end

struct Glyph
    points::Vector{Point}
    width::Real
end

"""
    generate_glyph_pts(origin::Point, width::Real, minheight::Real, maxheight::Real, shouldpolyfit::Bool = true)

Generate a random set of points representing a glyph.
The points are generated within an ellipse defined by the given width and height.
"""
function generate_glyph_pts(origin::Point, width::Real, minheight::Real, maxheight::Real, shouldpolyfit::Bool = true)
    b = (minheight + rand() * (maxheight - minheight)) / 2.0
    pts = distpointsinellipse(rand(3:6), origin, width / 2.0, b)

    if shouldpolyfit
        # Fit the points using a B-spline
        return polyfit(Vector{Point}(pts), 10)
    end

    return pts
end

function generate_glyph(origin::Point, width::Real, minheight::Real, maxheight::Real)
    pts = generate_glyph_pts(origin, width, minheight, maxheight)
    return Glyph(pts, width)
end

"""
    generate_glyph_map(width::Real, minheight::Real, maxheight::Real)

Generate a map of glyphs for the lowercase alphabet.
"""
function generate_glyph_map(width::Real, minheight::Real, maxheight::Real)
    glyph_map = Dict{Char, Glyph}()
    for c in 'a':'z'
        glyph_map[c] = generate_glyph(O, width, minheight, maxheight)
    end
    return glyph_map
end

function generate_word(length::Int)
    return rand('a':'z', length)
end

function renderword(word::Vector{Char}, glyphmap::Dict{Char, Glyph}, position::Point)
    wordpts = Vector{Point}()
    glyphs = map(c -> glyphmap[c], word)
    totalwidth = sum(glyph.width for glyph in glyphs)

    xpos = position.x + totalwidth > 7.5inch ? 0.5inch : position.x
    ypos = xpos == position.x ? position.y : position.y + 0.5inch

    for glyph in glyphs
        pos = Point(xpos, ypos)
        wordpts = vcat(wordpts, glyph.points .+ pos)
        xpos += glyph.width
    end

    poly(catmullromspline(wordpts), :stroke) 
    return Point(xpos, ypos)
end

pagewidth = 8inch
pageheight = 10inch

@draw begin
    setline(0.5)
    sethue("black")

    glyphmap = generate_glyph_map(0.5inch, 0.25inch, 0.75inch)
    words = [generate_word(rand(3:8)) for _ in 1:10]
    origin(0, 0)
    pos = Point(0.5inch, 1inch)

    for word in words
        global pos = renderword(word, glyphmap, pos)
    end

end pagewidth pageheight