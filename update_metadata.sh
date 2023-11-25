#!/bin/bash

find_json_recursively() {
    local file="$1"
    local base_directory="$2"
    local parent_directory="$3"

    local json_file
    json_file=$(find "$base_directory" -type d -exec test -e {}/"$file.json" \; -print | grep "$parent_directory")

    echo "$json_file"
}

process_files() {
    local input_directory="$1"
    local output_directory="$2"
    local suffix_enabled="$3"
    local suffix="$4"

    local total_files=0
    local success_count=0

    local tmpfile
    tmpfile=$(mktemp)
    find "$input_directory" -type f \( -iname "*.jpg" -o -iname "*.png" -o -iname "*.jpeg"  -o -iname "*.HEIC" -o -iname "*.gif" -o -iname "*.mp4" -o -iname "*.mov" \) -print0 > "$tmpfile"

    while IFS= read -r -d $'\0' photo; do
        ((total_files++))

        file_name=$(basename "$photo" | cut -d. -f1)

        file_name_ext=$(basename "$photo")
        file_name_ext_no_suffix=$(echo "$file_name_ext" | sed "s/$suffix\(\..*\)$/\1/")

        parent_directory=$(basename "$(dirname "$photo")")

        json_file=$(dirname "$photo")/"$file_name_ext_no_suffix.json"

        if [ ! -f "$json_file" ]; then
            json_file_recursive=$(find_json_recursively "$file_name_ext_no_suffix" "$input_directory" "$parent_directory")

            if [ -n "$json_file_recursive" ]; then
                json_file="$json_file_recursive/$file_name_ext_no_suffix.json"
            fi
        fi

        if [ -f "$json_file" ]; then
            exiftool -json="$json_file" -overwrite_original "$photo" > /dev/null 2>&1
            ((success_count++))

            mv "$photo" "$output_directory/"
        else
            mv "$photo" "$output_directory/"
        fi
    done < "$tmpfile"

    echo "$total_files $success_count"

    rm "$tmpfile"
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


echo ""
echo "👨🏻‍💻 Processing. It may take a while, make a coffee ☕️ or a nap 😴, depending on the input directory size."

read -r total_files success_count <<< "$(process_files "$input_directory" "$output_directory" "$suffix_enabled" "$suffix")"

if [ "$total_files" -gt 0 ]; then
    success_percentage=$(( (success_count * 100) / total_files ))
else
    success_percentage=0
fi

echo ""
echo "🎉🎉🎉 Completed 🎉🎉🎉"
echo ""

echo "📈 Results:"
echo "Total number of files processed: $total_files"
echo "Number of files successfully processed: $success_count"
echo "Success rate: $success_percentage%"

exit 0
