#!/bin/bash

find_json_recursively() {
    local file="$1"
    local base_directory="$2"
    local parent_directory="$3"

    local json_file
    json_file=$(find "$base_directory" -type d -exec test -e {}/"$file.json" \; -print | grep "$parent_directory")

    echo "$json_file"
}

read -p "🙋🏻‍♂️ Enter the input directory path: " input_directory

if [ ! -d "$input_directory" ]; then
    echo "🤨 The input directory does not exist. Exit."
    exit 1
fi

read -p "🙋🏻‍♂️ Enter the path to the output directory: " output_directory

if [ ! -d "$output_directory" ]; then
    mkdir -p "$output_directory"
    echo "😇 The directory has been created for you."
fi

read -p "🙋🏻‍♂️ Can files contain a suffix (ex: '-modified')? (y/n): " suffix_enabled

if [ "$suffix_enabled" == "y" ]; then
    read -p "🙋🏻‍♂️ Enter the suffix to use: " suffix
else
    suffix=""
fi

find "$input_directory" -type f \( -iname "*.jpg" -o -iname "*.png" -o -iname "*.jpeg"  -o -iname "*.HEIC" -o -iname "*.gif" -o -iname "*.mp4" -o -iname "*.mov" \) -print0 | while IFS= read -r -d $'\0' photo; do

    file_name=$(basename "$photo" | cut -d. -f1)

    file_name_ext=$(basename "$photo")
    file_name_ext_no_suffix=$(echo "$file_name_ext" | sed "s/$suffix\(\..*\)$/\1/")

    parent_directory=$(basename "$(dirname "$photo")")

    json_file=$(dirname "$photo")/"$file_name_ext_no_suffix.json"

    if [ ! -f "$json_file" ]; then
        json_file_recursive=$(find_json_recursively "$file_name_ext_no_suffix" "$input_directory" "$parent_directory")

        if [ -n "$json_file_recursive" ]; then
            json_file="$json_file_recursive/$file_name_ext_no_suffix.json"
            echo "🔎 JSON file found for $file_name_ext in other directory: $json_file"
        fi
    fi

    if [ -f "$json_file" ]; then
        exiftool -json="$json_file" -overwrite_original "$photo"

        echo "✅ JSON file found for $file_name_ext and updated successfully."
        mv "$photo" "$output_directory/"
    else
        echo "❌ JSON file not found for $file_name_ext in $json_file"
        mv "$photo" "$output_directory/"
    fi
done

echo ""
echo "🎉🎉🎉 Completed 🎉🎉🎉"
echo ""

exit 0