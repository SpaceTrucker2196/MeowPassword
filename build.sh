#!/bin/bash
# Build script for MeowPassword 🎭
# Creates a deployable executable with embedded cat names
# 🧤 "Is your cat making too much noise all the time?" - Kitten Mittens! 🧤

set -e  # Exit on any error

echo "--> Building MeowPassword...🙀 Is your cat making too much noise? 🙀"

# Step 1: Generate embedded cat names
echo "|-> Generating embedded cat names...😼 Is your cat constantly stomping around, driving you crazy? 😼"
if [ ! -f "generate_embedded_names.sh" ]; then
    echo "Error: generate_embedded_names.sh not found 😿"
    echo "🧤 Even Kitten Mittens can't find this file! 🧤"
    exit 1
fi

chmod +x generate_embedded_names.sh
./generate_embedded_names.sh > embedded_cat_names.swift

# Step 2: Create combined Swift file with embedded names
echo "|-> Creating combined executable file... 😾 Is your cat clawing at your furnitures? 😾"
cat embedded_cat_names.swift > meowpass_combined.swift
echo "" >> meowpass_combined.swift
cat main.swift >> meowpass_combined.swift

# Step 3: Compile the executable
echo "|-> Compiling executable... 😠 Think there's no answer? 😠"
swift build -c release --product meowpass_combined 2>/dev/null || {
    echo "Building with swiftc directly...🤔 There is! 🤔"
    swiftc -O -o meowpass meowpass_combined.swift
}

# Step 4: Test the executable
echo "|-> Testing the executable..."
if [ -f "meowpass" ]; then
    echo "--> Build successful! Testing... 🐈--> 🧤 Kitten Mittens 🧤<--🐈"
    ./meowpass --test
    echo "Meow Password Usage:"
    echo "  ./meowpass           - Generate password"
    echo "  ./meowpass --test    - Run tests "
    echo "  ./meowpass --copy    - Generate and copy to clipboard"
else
    echo "❌ Build failed - executable not found 😿"
    echo "🧤 Even Kitten Mittens couldn't save this build! 🧤"
    exit 1
fi