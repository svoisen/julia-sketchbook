using Luxor, CatmullRom, Distributions

height = 10inch
width = 8inch
margin = 0.5inch

bottom_cairn_height = 3inch
bottom_cairn_width = 5inch
stone_point_slop = 0.5inch

struct Stone
    bottom::Point
    height::Float64
    width::Float64
end

"""
    create_cairn(num_stones::Int, start_bottom::Point, start_height::Float64, start_width::Float64)

Create a cairn with `num_stones` stones, starting from `start_bottom` with the given height and width
and moving upwards with decreasing size.
"""
function create_cairn(num_stones::Int, start_bottom::Point, start_height::Float64, start_width::Float64)
    width, height, bottom = start_width, start_height, start_bottom
    for _ in 1:num_stones
        stone = Stone(bottom, height, width)
        bottom = draw_stone(stone)
        width *= 0.75
        height *= 0.75
    end
end

"""
    closed_spline(points::Vector{Point})

Create a closed Catmull-Rom spline from the given points.
"""
function closed_spline(points::Vector{Point})
    xs, ys = [p.x for p in points], [p.y for p in points]
    pts = collect(zip(xs, ys))
    close_seq!(pts)
    cxs, cys = catmullrom_by_arclength(pts)
    n = length(cxs)
    return [Point(cxs[i], cys[i]) for i in 1:n]
end

function draw_stone(stone::Stone)
    # slop() = rand(Uniform(-stone_point_slop, stone_point_slop))
    slop() = rand() * stone_point_slop * 2 - stone_point_slop

    left = Point(stone.bottom.x - stone.width / 2 + slop(),
                  stone.bottom.y - stone.height / 2 + slop())
    right = Point(stone.bottom.x + stone.width / 2 + slop(),
                   stone.bottom.y - stone.height / 2 + slop())
    top = Point(stone.bottom.x + rand() * stone_point_slop, 
                stone.bottom.y - stone.height)

    # Draw closed Catmull-Rom spline connecting the points
    spline = closed_spline([left, top, right, stone.bottom])
    poly(spline, :stroke)

    return top
end

@draw begin
    origin(0, 0)
    sethue("red")
    numlines = 20
    for i in 1:numlines
        y = easeoutquad(i, 0, height, numlines)
        x = 0
        line(Point(x, y), Point(width, y))
        strokepath()
    end

    sethue("black")
    create_cairn(5, Point(width / 2, height), bottom_cairn_height, bottom_cairn_width)
end width height