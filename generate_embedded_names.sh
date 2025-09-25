#!/bin/bash
# Script to convert catNamesText.txt into a Swift array format

echo "// MARK: - Embedded Cat Names Data"
echo "let embeddedCatNames: [String] = ["

# Read each line from catNamesText.txt and format as Swift string literal
while IFS= read -r line; do
    # Escape quotes and backslashes for Swift string literals
    escaped_line=$(echo "$line" | sed 's/\\/\\\\/g' | sed 's/"/\\"/g')
    echo "    \"$escaped_line\","
done < catNamesText.txt

echo "]"