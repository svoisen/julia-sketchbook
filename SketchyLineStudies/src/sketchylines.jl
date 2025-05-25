import Luxor as L
import CatmullRom as CR
using Plotline

function nudgepoint(p::L.Point, minradius::Real, maxradius::Real, minangle::Real = 0.0, maxangle::Real = 2 * π) 
    Ø = randombetween(minangle, maxangle)
    r = randombetween(minradius, maxradius)
    L.Point(p.x + r * cos(Ø), p.y + r * sin(Ø))
end

"""
    sketchyline(startpt::L.Point, endpt::L.Point, slop::Real)

Draw a sketchy (hand-drawn) line between two points with a given slop (roughness) factor.
"""
function sketchyline(startpt::L.Point, endpt::L.Point, slop::Real = 0.5mm; backtick_prob::Real = 0.5)
    # Calculate a point roughly mid-way along the line
    midmul = randombetween(0.4, 0.5)
    midpt = L.Point(startpt.x + (endpt.x - startpt.x) * midmul, startpt.y + (endpt.y - startpt.y) * midmul)

    # Calculate a point roughly 3/4 of the way along the line
    midmul = randombetween(0.75, 0.85)
    midpt2 = L.Point(startpt.x + (endpt.x - startpt.x) * midmul, startpt.y + (endpt.y - startpt.y) * midmul)

    # Calculate the angle orthogonal to the line
    ortho_angle = atan(endpt.y - startpt.y, endpt.x - startpt.x) + π / 2

    # Move the midpt and midpt2 points in a random direction along the orthogonal vector
    # with a random slop factor in the SAME direction, but with different magnitudes
    midpt_mag = randombetween(0.0, slop)
    midpt2_mag = randombetween(0.0, slop)
    midpt_offset = L.Point(cos(ortho_angle) * midpt_mag, sin(ortho_angle) * midpt_mag)
    midpt2_offset = L.Point(cos(ortho_angle) * midpt2_mag, sin(ortho_angle) * midpt2_mag)

    if rand() < 0.5
        midpt += midpt_offset
        midpt2 += midpt2_offset
    else
        midpt -= midpt_offset
        midpt2 -= midpt2_offset
    end

    points = [nudgepoint(startpt, 0.0, slop), midpt, midpt2, nudgepoint(endpt, 0.0, slop)]

    # Use a Catmull-Rom spline to create a smooth curve through the points
    spline_points = [(p.x, p.y) for p in points]
    cxs, cys = CR.catmullrom(spline_points)

    # Randomly add a backtick point to the end of the line
    if rand() > backtick_prob
        backtick_point = nudgepoint(endpt, slop, slop, ortho_angle + π/4.0, ortho_angle + (3.0 * π) / 4.0)
        push!(cxs, backtick_point.x)
        push!(cys, backtick_point.y)
    end

    return L.Path([L.Point(cx, cy) for (cx, cy) in zip(cxs, cys)])
end

L.@draw begin
    width = 500
    height = 500
    margin = 50
    numlines = 10
    L.origin(0, 0)

    for i in 0:numlines
        y = i / numlines * height + margin
        startpt = L.Point(margin, y)
        endpt = L.Point(width - margin, y)
        path = sketchyline(startpt, endpt, 4.0)
        L.sethue("black")
        L.drawpath(path)
        L.strokepath()
    end
end