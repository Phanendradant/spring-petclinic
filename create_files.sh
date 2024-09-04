#!/bin/bash

# Create the "projects" directory
mkdir -p projects

# Create directories as per the structure
mkdir -p projects/facebook
mkdir -p projects/google/oriserve
mkdir -p projects/meta/oriserve
mkdir -p projects/oracle

# Find all "oriserve" directories under the "projects" directory
find projects -type d -name "oriserve" | while read dir; do
  # Create "test.txt" inside each "oriserve" directory
  touch "$dir/test.txt"
done

# Output the directory structure and contents
echo "Directory structure and contents:"
tree projects

