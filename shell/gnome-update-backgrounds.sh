#!/usr/bin/env bash

# Check if the correct number of arguments is provided
if [ "$#" -ne 1 ]; then
  echo "Usage: $(basename $0) <directory_with_pictures>"
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
shopt -s nocaseglob
for file in "$source_dir"/*.{jpeg,jpg,png,tga}; do
    # Check if it is a file
    if [ -f "$file" ]; then
        # Get the name and the date of the file
        name=$(basename "$file")
        date=$(date -r "$file" "+%Y-%m-%d-%H-%M-%S")

        # Create the target filename
        link="$target_dir/$date-$name"

        # Check inodes
        file_inode=$(ls -i "$file" | awk '{print $1}')
        link_inode=$(ls -i "$link" 2> /dev/null | awk '{print $1}')

        if [ "$file_inode" != "$link_inode" ]; then
            # Tell us about it
            echo "Linking $link"

            # Create a hard link in the target directory
            ln -f "$file" "$link"
        fi
    fi
done
