using Luxor
using ArgParse
using ImageMorphology
using Images
using JSON
using GeoInterface
using GeometryOps

"""
    parse_cli_args()

Parse command line arguments for the script.
"""
function parse_cli_args()
    s = ArgParseSettings()
    @add_arg_table s begin
        "--input", "-i"
            help = "Input image file path"
            required = true
            arg_type = String
        "--output", "-o"
            help = "Output JSON data path"
            default = "output.json"
            arg_type = String
        "--threshold", "-t"
            help = "Threshold for edge detection"
            default = 0.5
            arg_type = Float64
        "--tolerance", "-e"
            help = "Tolerance for path simplification (Douglas-Peucker algorithm)"
            default = 1.0
            arg_type = Float64
        "--visualize", "-v"
            help = "Visualize the skeleton and paths"
            default = false
            action = :store_true
    end

    return parse_args(s)
end

function output_skeleton(skeleton::BitMatrix, output_path::String)
    img = Gray.(ones(size(skeleton)))
    img[skeleton] .= 0.0
    save(output_path, img)
end

"""
    get_adjacent_pixels(skeleton::BitMatrix, i::Int, j::Int)

Get all valid 8-connected adjacent pixels of a given pixel.
Returns a vector of (row, col) tuples for each valid adjacent pixel.
"""
function get_adjacent_pixels(skeleton::BitMatrix, i::Int, j::Int)
    height, width = size(skeleton)
    adjacent = Tuple{Int, Int}[]
    
    for di in -1:1
        for dj in -1:1
            if di == 0 && dj == 0
                continue
            end
            
            ni, nj = i + di, j + dj
            if 1 <= ni <= height && 1 <= nj <= width && skeleton[ni, nj]
                push!(adjacent, (ni, nj))
            end
        end
    end
    
    return adjacent
end

"""
    count_neighbors(skeleton::BitMatrix, i::Int, j::Int)

Count the number of neighboring pixels that are 1s in the skeleton image.
"""
function count_neighbors(skeleton::BitMatrix, i::Int, j::Int)
    return length(get_adjacent_pixels(skeleton, i, j))
end

"""
    get_next_pixel(skeleton::BitMatrix, i::Int, j::Int)

Get the next pixel in a path by looking at the 8-connected neighbors.
Returns the coordinates of the next pixel or nothing if there are no valid neighbors.
"""
function get_next_pixel(skeleton::BitMatrix, i::Int, j::Int)
    adjacent = get_adjacent_pixels(skeleton, i, j)
    return isempty(adjacent) ? nothing : adjacent[1]
end

"""
    find_endpoints_and_junctions(skeleton::BitMatrix)

Find all endpoints (pixels with 1 neighbor) and junctions (pixels with 3+ neighbors) 
in a skeletonized image.

Returns a tuple of (endpoints, junctions) where each is a vector of (i, j) coordinates.
"""
function find_endpoints_and_junctions(skeleton::BitMatrix)
    height, width = size(skeleton)
    endpoints = Tuple{Int, Int}[]
    junctions = Tuple{Int, Int}[]
    
    for i in 1:height
        for j in 1:width
            if skeleton[i, j]
                num_neighbors = count_neighbors(skeleton, i, j)
                if num_neighbors == 1
                    # It's an endpoint
                    push!(endpoints, (i, j))
                elseif num_neighbors >= 3
                    # It's a junction
                    push!(junctions, (i, j))
                end
            end
        end
    end
    
    return endpoints, junctions
end

function first_nonempty_pixel(skeleton::BitMatrix)
    for i in 1:height
        for j in 1:width
            if skeleton[i, j]
                return (i, j)
            end
        end
    end

    return nothing
end

"""
    extract_paths(skeleton::BitMatrix)

Extract paths from a skeletonized image.
Returns a vector of vectors, where each inner vector is a series of (x,y) points
representing a single stroke path.
"""
function extract_paths(skeleton::BitMatrix)
    # Create a copy of the skeleton that we can modify
    # We will use this to mark pixels as processed as we extract paths
    working_skeleton = copy(skeleton)
    height, width = size(working_skeleton)
    
    # Find endpoints and junctions
    endpoints, junctions = find_endpoints_and_junctions(working_skeleton)
    
    # If no endpoints are found, find a pixel to start from
    if isempty(endpoints)
        point = first_nonempty_pixel(working_skeleton)
        if point === nothing
            println("Warning: No non-empty pixels in skeleton image")
            return []
        end
        push!(endpoints, point)
    end

    paths = Vector{Vector{Tuple{Int, Int}}}()
    
    # Start from each endpoint or junction
    start_points = [endpoints; junctions]
    
    for (start_i, start_j) in start_points
        # Skip if the pixel has already been processed
        !working_skeleton[start_i, start_j] && continue
        
        path = [(start_i, start_j)]
        working_skeleton[start_i, start_j] = false
        
        # Follow the path until we reach an endpoint or junction
        i, j = start_i, start_j
        while true
            next = get_next_pixel(working_skeleton, i, j)
            
            # End of path
            if next === nothing
                break
            end
            
            next_i, next_j = next
            push!(path, (next_i, next_j))
            working_skeleton[next_i, next_j] = false
            
            # If we've reached a junction, stop
            if count_neighbors(working_skeleton, next_i, next_j) >= 2
                break
            end
            
            i, j = next_i, next_j
        end
        
        # Only save paths with more than 1 point
        if length(path) > 1
            # Convert from image coordinates (row, col) to Cartesian coordinates (x, y)
            cartesian_path = [(j, i) for (i, j) in path]
            push!(paths, cartesian_path)
        end
    end
    
    return paths
end

"""
    fit_paths_to_splines(paths, num_points::Int=10)

Fit each path to a B-spline curve using Luxor's polyfit function.
This smooths out the paths before simplification.
"""
function fit_paths_to_splines(paths, num_points::Int=10)
    fitted_paths = Vector{Vector{Tuple{Int, Int}}}()
    
    for path in paths
        # Convert to Luxor Points for polyfit
        luxor_points = [Luxor.Point(x, y) for (x, y) in path]
        
        # Only fit if we have enough points
        if length(luxor_points) >= 3
            # Fit to B-spline
            fitted_points = Luxor.polyfit(luxor_points, num_points)
            
            # Convert back to our format
            fitted_path = [(round(Int, p.x), round(Int, p.y)) for p in fitted_points]
            push!(fitted_paths, fitted_path)
            println("Fitted path with $(length(fitted_path)) points, down from $(length(path))")
        else
            # Not enough points to fit, keep original
            push!(fitted_paths, path)
        end
    end
    
    return fitted_paths
end

"""
    simplify_paths(paths, tolerance::Float64=1.0)

Simplify paths using the Douglas-Peucker algorithm to reduce the number of points
while preserving the essential shape.
"""
function simplify_paths(paths, tolerance::Float64=1.0)
    simplified_paths = Vector{Vector{Tuple{Int, Int}}}()
    
    for path in paths
        # Skip paths that are too short to simplify
        if length(path) <= 2
            push!(simplified_paths, path)
            continue
        end

        coords = [[x, y] for (x, y) in path]
        linestring = GeoInterface.LineString(coords)
        
        # Simplify the LineString
        simplified = GeometryOps.simplify(DouglasPeucker(tol=tolerance), linestring)
        
        # Convert back to our path format
        simplified_coords = GeoInterface.coordinates(simplified)
        simplified_path = [(round(Int, point[1]), round(Int, point[2])) for point in simplified_coords]
        
        push!(simplified_paths, simplified_path)
    end
    
    return simplified_paths
end

"""
    save_paths_as_json(paths, output_path::String)

Save the extracted paths as JSON data to the specified output path.
Each path is a vector of (x, y) coordinates.
"""
function save_paths_as_json(paths, output_path::String)
    # Convert paths to a format better suited for JSON
    json_data = Dict(
        "paths" => [
            [Dict("x" => point[1], "y" => point[2]) for point in path]
            for path in paths
        ],
        "num_paths" => length(paths)
    )
    
    open(output_path, "w") do io
        JSON.print(io, json_data, 4)  # Use 4 spaces for indentation
    end
    
    println("Paths saved to $output_path")
    return true
end

function skeletonize_image(image_path::String, threshold::Float64=0.5)
    img = load(image_path)
    gray_img = Gray.(img)
    binary_img = gray_img .< threshold
    return ImageMorphology.thinning(binary_img)
end

function process_image(image_path::String, output_path::String, threshold::Float64=0.5, tolerance::Float64=10.0, visualize::Bool=false)
    println("Processing image: $image_path")

    try
        skeleton = skeletonize_image(image_path, threshold)
        
        # Extract paths from the skeleton
        paths = extract_paths(skeleton)
        println("Extracted $(length(paths)) paths with $(sum(length.(paths))) total points")
        
        # Fit paths to splines for smoother curves
        # fitted_paths = fit_paths_to_splines(paths)
        # println("Fitted paths to splines")
        
        # Simplify paths
        simplified_paths = simplify_paths(paths, tolerance)
        println("Simplified to $(sum(length.(simplified_paths))) total points")

        # Save paths as JSON
        save_paths_as_json(simplified_paths, output_path)

        if visualize
            output_skeleton(skeleton, "skeleton.png")
            
            # Visualize the extracted paths
            img_paths = RGB.(zeros(size(skeleton)))
            colors = distinguishable_colors(length(paths), [RGB(1,1,1), RGB(0,0,0)])
            
            for (i, path) in enumerate(paths)
                for (x, y) in path
                    if 1 <= y <= size(img_paths, 1) && 1 <= x <= size(img_paths, 2)
                        img_paths[y, x] = colors[i]
                    end
                end
            end
            
            save("paths.png", img_paths)
            
            # Also save the fitted paths before simplification
            # img_fitted = RGB.(zeros(size(skeleton)))
            # for (i, path) in enumerate(fitted_paths)
            #     for (x, y) in path
            #         if 1 <= y <= size(img_fitted, 1) && 1 <= x <= size(img_fitted, 2)
            #             img_fitted[y, x] = colors[i]
            #         end
            #     end
            # end
            
            # save("fitted_paths.png", img_fitted)
        end

        return true
    catch e
        println("Error processing image: $e")
        return false
    end
end

function main()
    args = parse_cli_args()

    input_path = args["input"]
    output_path = args["output"]
    threshold = args["threshold"]
    tolerance = args["tolerance"]
    visualize = args["visualize"]
    success = process_image(input_path, output_path, threshold, tolerance, visualize)
    return success ? 0 : 1
end

if abspath(PROGRAM_FILE) == @__FILE__
    exit(main())
end