#!/bin/bash
set -e

echo "Making all .sh files executable..."

# Find all files ending in .sh in the current directory and its subdirectories,
# and make them executable.
# -print0 and xargs -0 are used to handle filenames with spaces or special characters.
find .. -type f -name "*.sh" -print0 | xargs -0 chmod +x

echo "All .sh files have been made executable."
