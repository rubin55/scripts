#!/usr/bin/env bash

# Check if the correct number of arguments is provided
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <directory_with_pictures>"
    exit 1
fi

# Assign arguments to variables
source_dir="$1"
target_dir="$HOME/.local/share/backgrounds"

# Check if the source directory exists
if [ ! -d "$source_dir" ]; then
    echo "Source directory does not exist: $source_dir"
    exit 1
fi

# Check if the target directory exists, if not, create it
if [ ! -d "$target_dir" ]; then
    echo "Target directory does not exist: $target_dir"
    exit 1
fi

# Iterate over each file in the source directory
for file in "$source_dir"/*; do
    # Check if it is a file
    if [ -f "$file" ]; then
        # Get the filename and the date of the file
        file_name=$(basename "$file")
        file_date=$(date -r "$file" "+%Y-%m-%d-%H-%M-%S")

        # Create the target filename
        file_link="$target_dir/$file_date-$file_name"

        # Tell us about it
        echo "Linking to $file_link"

        # Create a hard link in the target directory
        ln -f "$file" "$file_link"
    fi
done
