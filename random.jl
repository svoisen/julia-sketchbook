module Random

using Luxor

"""
    pointcloud(n::Int)

Generate a point cloud of `n` points in a given rectangle.
"""
function pointcloud(n::Int, minx::Float64=0., miny::Float64=0., maxx::Float64=400., maxy::Float64=400.)
    return [Luxor.randompoint(Point(minx, miny), Point(maxx, maxy)) for _ in 1:n]
end

function distributed_pointcloud(n::Int, k:Int=100, minx::Float64=0., miny::Float64=0., maxx::Float64=400., maxy::Float64=400.)
    points = Point[Luxor.randompoint(Point(minx, miny), Point(maxx, maxy))]

    for _ in 2:n
        # Take k random samples and choose the point with
        # the largest minimum distance to the existing samples
        best_distance = 0.0
        best_point = nothing
        for _ in 1:k
            point = Luxor.randompoint(Point(minx, miny), Point(maxx, maxy))
            distances = [Luxor.distance(point, p) for p in points]
            shortest_distance = minimum(distances)
            if shortest_distance > best_distance
                best_distance = shortest_distance
                best_point = point
            end 
        end

        push!(points, best_point)
    end

    return points
end

end