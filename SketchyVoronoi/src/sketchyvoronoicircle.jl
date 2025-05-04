using Luxor, Plotline, DelaunayTriangulation

"""
Exploration of sketchy hatching of Voronoi tesselations with an irregular clipping circle.
"""

width = 8inch
height = 8inch

# Radius of the clipping circle
radius = 3inch

# Number of points to use for the Voronoi tesselation
# More points will make the Voronoi tesselation more complex
numpoints = 40

# Number of points in the clipping circle, more points will make the circle smoother
num_clipping_points = 10

clipping_circle_pts = [(radius * cos(2 * π * i / num_clipping_points), radius * sin(2 * π * i / num_clipping_points)) for i in 0:num_clipping_points-1]
indices = [i for i in 1:num_clipping_points]
clipping_circle = (clipping_circle_pts, indices)

points = distpointsincircle(numpoints, O, sqrt(width^2 + height^2) / 2)
triangulation = triangulate([(p.x, p.y) for p in points])

smoothed_voronoi = centroidal_smooth(voronoi(triangulation); predicates = FastKernel())
clipped_voronoi = DelaunayTriangulation.clip_voronoi_tessellation!(smoothed_voronoi, clip_polygon=clipping_circle)
polygons = clipped_voronoi.polygons
polygons_points = DelaunayTriangulation.get_polygon_points(clipped_voronoi)

@draw begin
    background("white")

    local Ø = 0
    for polygon in each_polygon(clipped_voronoi)
        local points = [Point(polygons_points[i][1], polygons_points[i][2]) for i in polygon]
        inset_polygon = offset(points, -2.0)

        # Close the polygon
        push!(inset_polygon, inset_polygon[1])

        sethue("red")
        sketchyhatch(inset_polygon, Ø, 5, 0.25mm)

        sethue("blue")
        sketchyhatch(inset_polygon, -Ø, 5, 0.25mm)

        Ø += 22.5
    end

end width height