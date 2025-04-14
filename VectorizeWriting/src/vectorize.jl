using Luxor
using ArgParse
using ImageMorphology
using Images

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
                neighbors = count_neighbors(skeleton, i, j)
                if neighbors == 1
                    # It's an endpoint
                    push!(endpoints, (i, j))
                elseif neighbors >= 3
                    # It's a junction
                    push!(junctions, (i, j))
                end
            end
        end
    end
    
    return endpoints, junctions
end

"""
    extract_paths(skeleton::BitMatrix)

Extract paths from a skeletonized image.
Returns a vector of vectors, where each inner vector is a series of (x,y) points
representing a single stroke path.
"""
function extract_paths(skeleton::BitMatrix)
    # Create a copy of the skeleton that we can modify
    working_skeleton = copy(skeleton)
    height, width = size(working_skeleton)
    
    # Find endpoints and junctions
    endpoints, junctions = find_endpoints_and_junctions(working_skeleton)
    
    # If no endpoints are found, find a pixel to start from
    if isempty(endpoints)
        for i in 1:height
            for j in 1:width
                if working_skeleton[i, j]
                    push!(endpoints, (i, j))
                    break
                end
            end
            !isempty(endpoints) && break
        end
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

function skeletonize_image(image_path::String, threshold::Float64=0.5)
    img = load(image_path)
    gray_img = Gray.(img)
    binary_img = gray_img .< threshold
    return ImageMorphology.thinning(binary_img)
end

function process_image(image_path::String, threshold::Float64=0.5, visualize::Bool=false)
    println("Processing image: $image_path")

    try
        skeleton = skeletonize_image(image_path, threshold)
        
        # Extract paths from the skeleton
        paths = extract_paths(skeleton)
        println("Extracted $(length(paths)) paths")

        if visualize
            output_skeleton(skeleton, "skeleton.png")
            
            # Visualize the extracted paths
            img_paths = RGB.(zeros(size(skeleton)))
            colors = distinguishable_colors(length(paths), [RGB(1,1,1), RGB(0,0,0)])
            
            for (i, path) in enumerate(paths)
                for (x, y) in path
                    img_paths[y, x] = colors[i]
                end
            end
            
            save("paths.png", img_paths)
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
    threshold = args["threshold"]
    visualize = args["visualize"]
    success = process_image(input_path, threshold, visualize)
    return success ? 0 : 1
end

if abspath(PROGRAM_FILE) == @__FILE__
    exit(main())
end