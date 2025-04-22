using Images
using FileIO
using ImageView
using ProgressMeter
using ImageMorphology

"""
    skeletonize_image(img)

Convert an image to its skeleton representation.
"""
function skeletonize_image(image, threshold::Float64 = 0.5)
    gray_img = Gray.(image)
    binary_img = gray_img .< threshold
    return ImageMorphology.thinning(binary_img) 
end

"""
    process_directory(input_dir, output_dir)

Process all images in the input directory and save the skeletonized versions 
to the output directory with "_skeleton" suffix.

# Arguments
- `input_dir`: Path to directory containing input images
- `output_dir`: Path to directory where output images will be saved
"""
function skeletonize(input_dir::String, output_dir::String)
    if !isdir(output_dir)
        mkpath(output_dir)
        println("Created output directory: $output_dir")
    end
    
    image_extensions = [".png"]
    files = filter(f -> any(endswith.(lowercase(f), image_extensions)), readdir(input_dir, join=true))
    
    if isempty(files)
        println("No image files found in $input_dir")
        return
    end
    
    println("Found $(length(files)) image files to process")
    
    @showprogress "Processing images..." for file_path in files
        # Get filename without path and extension
        filename = basename(file_path)
        name, ext = splitext(filename)
        output_filename = "$(name)_skeleton$(ext)"
        output_path = joinpath(output_dir, output_filename)
        
        try
            img = load(file_path)
            skeleton_img = skeletonize_image(img)
            save(output_path, skeleton_img)
        catch e
            println("Error processing $filename: $e")
        end
    end
    
    println("Processing complete! Skeletonized images saved to $output_dir")
end

"""
    main()

Main function to run the skeletonization process.
"""
function main()
    if length(ARGS) < 2
        println("Usage: julia skeletonize.jl <input_directory> <output_directory>")
        exit(1)
    end
    
    input_dir = ARGS[1]
    output_dir = ARGS[2]
    
    if !isdir(input_dir)
        println("Error: Input directory '$input_dir' does not exist.")
        exit(1)
    end
    
    skeletonize(input_dir, output_dir)
end

# Run the script if called directly
if abspath(PROGRAM_FILE) == @__FILE__
    main()
end