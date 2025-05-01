using Luxor
using CatmullRom

width = 500.0
height = 500.0

function randomcurve(starty::Float64, startx::Float64, endx::Float64, multiplier::Float64 = 10.0)
    xs = range(startx, endx, 50)
    ys = Vector{Float64}(undef, length(xs))
    y = starty
    for i in 1:length(xs)
        y += randn() * multiplier
        ys[i] = y
    end

    return collect(zip(xs, ys))
end

@draw begin
    origin(0, 0)
    background("white")
    sethue("blue")
    ridge = randomcurve(height / 2.0, 0.0, width, 5.0)
    for i in 1:length(ridge)-1
        p1 = Point(ridge[i][1], ridge[i][2])
        p2 = Point(ridge[i+1][1], ridge[i+1][2])
        line(p1, p2, :stroke)
    end

    # sethue("red")
    # cxs, cys = catmullrom(ridge)
    # points = [Point(x, y) for (x, y) in ridge]
    # poly(points, :stroke)
end width height