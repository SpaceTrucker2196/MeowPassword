#!/bin/bash
# Build script for MeowPassword
# Creates a deployable executable with embedded cat names

set -e  # Exit on any error

echo "Building MeowPassword meow..."

# Step 1: Generate embedded cat names
echo "Generating embedded meow cat names..."
if [ ! -f "generate_embedded_names.sh" ]; then
    echo "Error: generate_embedded_names.sh not found"
    exit 1
fi

chmod +x generate_embedded_names.sh
./generate_embedded_names.sh > embedded_cat_names.swift

# Step 2: Create combined Swift file with embedded names
echo "Creating combined meow executable file..."
cat embedded_cat_names.swift > meowpass_combined.swift
echo "" >> meowpass_combined.swift
cat main.swift >> meowpass_combined.swift

# Step 3: Compile the executable
echo "Compiling meow executable..."
swift build -c release --product meowpass_combined 2>/dev/null || {
    echo "Building with swiftc directly..."
    swiftc -O -o meowpass meowpass_combined.swift
}

# Step 4: Test the executable
echo "Testing the meow executable..."
if [ -f "meowpass" ]; then
    echo "Build successful! Testing..."
    ./meowpass --test
    echo ""
    echo "MeowPassword built successfully!"
    echo "Usage:"
    echo "  ./meowpass           - Generate password"
    echo "  ./meowpass --test    - Run tests"
    echo "  ./meowpass --copy    - Generate and copy to clipboard"
else
    echo "Build failed - executable not found"
    exit 1
fi