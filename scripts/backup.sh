#!/bin/bash

# This script zips a folder into a zip file with a timestamp in the filename.
# It is intended to be used to backup a folder.

# Check if the user provided a folder name as an argument
if [ -z "$1" ]; then
    echo "Usage: $0 <folder_name>"
    exit 1
fi

# Remove trailing slash from folder name if it exists (for cleaner filenames)
FOLDER_NAME=$(echo "$1" | sed 's:/*$::')

# Check if the folder actually exists
if [ ! -d "$FOLDER_NAME" ]; then
    echo "Error: Folder '$FOLDER_NAME' not found."
    exit 1
fi

# Create date stamp in ISO format (Year-Month-Day-HoursMinutesSeconds)
DATE=$(date +%Y-%m-%d-%H%M%S)

# Set the output filename
ZIP_NAME="${FOLDER_NAME}-${DATE}.zip"

# Create the zip file
echo "Zipping '$FOLDER_NAME' into '$ZIP_NAME'..."
zip -r "$ZIP_NAME" "$FOLDER_NAME"

# Check if the zip command was successful
if [ $? -eq 0 ]; then
    echo "Success! File created: $ZIP_NAME"
else
    echo "Error: Something went wrong while creating the zip file."
fi
