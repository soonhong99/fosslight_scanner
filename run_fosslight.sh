#!/bin/bash
# run_fosslight.sh

# Parse command line arguments
while getopts ":p:o:" opt; do
  case $opt in
    p) SOURCE_PATH="$OPTARG"
    ;;
    o) OUTPUT_PATH="$OPTARG"
    ;;
    \?) echo "Invalid option -$OPTARG" >&2
    exit 1
    ;;
  esac
done

# Ensure source path is provided
if [ -z "$SOURCE_PATH" ]; then
  echo "Error: Source path (-p) is required."
  exit 1
fi

# Use current directory as output path if not specified
OUTPUT_PATH=${OUTPUT_PATH:-$(pwd)}

# Run Docker command
docker run --rm \
  --volume-driver custom_volume_plugin \
  -v "$SOURCE_PATH":/src \
  -v "$OUTPUT_PATH":/output \
  fosslight_path fosslight_source -p /src -o /output

# 만약 fosslight_dependency를 쓰고 싶다면?
# 왜 전체 경로를 써줘야지 되는거야?