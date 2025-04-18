using Luxor
using ArgParse
using JSON
using Plotline

"""
    parse_cli_args()

Parse command line arguments for the script.
"""
function parse_cli_args()
    s = ArgParseSettings()
    @add_arg_table s begin
        "--input", "-i"
            help = "Input JSON file path containing vectorized paths"
            required = true
            arg_type = String
        "--output", "-o"
            help = "Output image file path"
            default = "rendered_paths.png"
            arg_type = String
    end

    return parse_args(s)
end

"""
    load_paths_from_json(json_path::String)

Load paths from a JSON file and convert them to vectors of Luxor.Point
"""
function load_paths_from_json(json_path::String)
    # Read the JSON file
    json_data = open(json_path, "r") do io
        JSON.parse(io)
    end
    
    # Extract paths from the JSON data
    paths = Vector{Vector{Point}}()
    
    for json_path in json_data["paths"]
        points = [Point(point["x"], point["y"]) for point in json_path]
        push!(paths, points)
    end
    
    return paths
end

"""
    render_paths(paths::Vector{Vector{Point}}, args)

Render the paths to an image file using Luxor.
"""
function render_paths(paths::Vector{Vector{Point}}, args)
    width = 8inch
    height = 10inch
    
    # Calculate the bounds of all paths to center them in the image
    all_points = vcat(paths...)
    min_x = minimum(p.x for p in all_points)
    max_x = maximum(p.x for p in all_points)
    min_y = minimum(p.y for p in all_points)
    max_y = maximum(p.y for p in all_points)
    
    # Calculate scale to fit the paths in the image with some padding
    path_width = max_x - min_x
    path_height = max_y - min_y
    padding = 0.5inch
    
    scale_x = (width - 2 * padding) / path_width
    scale_y = (height - 2 * padding) / path_height
    scale_factor = min(scale_x, scale_y)
    
    # Calculate the offset to center the paths
    offset_x = width / 2 - (min_x + path_width / 2) * scale_factor
    offset_y = height / 2 - (min_y + path_height / 2) * scale_factor
    
    # Create the drawing
    @svg begin
        background("white")
        sethue("black")
        setline(1)

        for path in paths
            # Transform points to fit the drawing
            transformed_path = [Point(
                p.x * scale_factor + offset_x,
                p.y * scale_factor + offset_y
            ) for p in path]
            
            # Draw the path using a Catmull-Rom spline for smooth curves
            if length(transformed_path) >= 3
                poly(catmullromspline(path), :stroke)
            end
        end
    end width height 
    
    return true
end

function main()
    args = parse_cli_args()
    
    # Load paths from JSON file
    paths = load_paths_from_json(args["input"])
    println("Loaded $(length(paths)) paths")
    
    # Render paths to an image
    success = render_paths(paths, args)
    
    return success ? 0 : 1
end

if abspath(PROGRAM_FILE) == @__FILE__
    exit(main())
end
