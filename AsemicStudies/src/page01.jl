using Luxor, Plotline

struct DiacriticMark
    points::Vector{Vector{Point}}
    width::Real
end

struct Glyph
    points::Vector{Point}
    width::Real
end

pagewidth = 8inch
pageheight = 10inch
margin = 0.5inch
lineheight = 0.75inch

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
    pts = generate_glyph_pts(origin, width, minheight, maxheight, true)
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
    twoglyph_width = sum(glyph.width for glyph in glyphs[1:2])
    xpos, ypos = position.x, position.y

    if xpos + twoglyph_width > 7.5inch
        xpos = 0.5inch
        ypos += lineheight
    else
        # Truncate the word to fit within the page width
        while length(glyphs) > 2 && xpos + sum(glyph.width for glyph in glyphs) > 7.5inch
            glyphs = glyphs[1:end-1]
        end
    end

    for glyph in glyphs
        pos = Point(xpos, ypos)
        wordpts = vcat(wordpts, glyph.points .+ pos)
        xpos += glyph.width
    end

    poly(catmullromspline(wordpts), :stroke) 
    return Point(xpos, ypos)
end

@svg begin
    setline(1.5)
    sethue("black")

    glyphmap = generate_glyph_map(0.5inch, 0.25inch, 0.75inch)
    words = [generate_word(rand(3:8)) for _ in 1:30]
    origin(0, 0)
    pos = Point(margin, margin)

    for word in words
        global pos = renderword(word, glyphmap, pos)
    end

end pagewidth pageheight