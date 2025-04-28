#!/bin/bash

# Function to show usage/help
show_help() {
    echo "Usage: $0 [options] search_string filename"
    echo "Options:"
    echo "  -n    Show line numbers"
    echo "  -v    Invert match (show lines that do NOT match)"
    echo "  -c    Only show the count of matching lines"
    echo "  -l    Only print the filename if matches found"
    echo "  --help Show this help message"
}

# Check if no arguments
if [ $# -eq 0 ]; then
    show_help
    exit 1
fi

# Initialize variables
show_line_numbers=false
invert_match=false
count_only=false
list_filename=false

# Handle long options manually (like --help)
for arg in "$@"; do
    if [[ "$arg" == "--help" ]]; then
        show_help
        exit 0
    fi
done

# Parse short options using getopts
while getopts ":nvcl" opt; do
    case "$opt" in
        n)
            show_line_numbers=true
            ;;
        v)
            invert_match=true
            ;;
        c)
            count_only=true
            ;;
        l)
            list_filename=true
            ;;
        \?)
            echo "Unknown option: -$OPTARG"
            show_help
            exit 1
            ;;
    esac
done

# Shift parsed options away
shift $((OPTIND-1))

#  $1  search string, $2  filename
search_string="$1"
filename="$2"

# Check if search string and file are provided
if [ -z "$search_string" ] || [ -z "$filename" ]; then
    echo "Error: Missing search string or filename."
    show_help
    exit 1
fi

# Check if file exists
if [ ! -f "$filename" ]; then
    echo "Error: File '$filename' does not exist."
    exit 1
fi

# Check if file is readable
if [ ! -r "$filename" ]; then
    echo "Error: File '$filename' is not readable."
    exit 1
fi

# Main functionality
line_number=0
match_count=0
match_found_global=false

while IFS= read -r line; do
    ((line_number++))
    # Perform case-insensitive search
    if echo "$line" | grep -iq "$search_string"; then
        match_found=true
    else
        match_found=false
    fi

    # Handle invert match
    if [ "$invert_match" = true ]; then
        if [ "$match_found" = true ]; then
            match_found=false
        else
            match_found=true
        fi
    fi

    if [ "$match_found" = true ]; then
        match_found_global=true
        ((match_count++))

        # If -c or -l is set, don't print individual lines
        if [ "$count_only" = false ] && [ "$list_filename" = false ]; then
            if [ "$show_line_numbers" = true ]; then
                echo "${line_number}:$line"
            else
                echo "$line"
            fi
        fi
    fi
done < "$filename"

# If -c (count matches) is requested
if [ "$count_only" = true ]; then
    echo "$match_count"
fi

# If -l (list filename if any match) is requested
if [ "$list_filename" = true ] && [ "$match_found_global" = true ]; then
    echo "$filename"
fi

