#!/bin/bash
# Build script for MeowPassword 🎭
# Creates a deployable executable with embedded cat names
# 🧤 "Is your cat making too much noise all the time?" - Kitten Mittens! 🧤

set -e  # Exit on any error

echo "Building MeowPassword meow... 🐾"
echo "🧤 Kitten Mittens approved build process! 🧤"

# Step 1: Generate embedded cat names
echo "Generating embedded meow cat names... 📝"
echo "🧤 Kitten Mittens: Quietly generating your cat names! 🧤"
if [ ! -f "generate_embedded_names.sh" ]; then
    echo "Error: generate_embedded_names.sh not found 😿"
    echo "🧤 Even Kitten Mittens can't find this file! 🧤"
    exit 1
fi

chmod +x generate_embedded_names.sh
./generate_embedded_names.sh > embedded_cat_names.swift

# Step 2: Create combined Swift file with embedded names
echo "Creating combined meow executable file... 🔧"
echo "🧤 Kitten Mittens: Softly combining your files! 🧤"
cat embedded_cat_names.swift > meowpass_combined.swift
echo "" >> meowpass_combined.swift
cat main.swift >> meowpass_combined.swift

# Step 3: Compile the executable
echo "Compiling meow executable... ⚙️"
echo "🧤 Kitten Mittens: Making compilation quieter than ever! 🧤"
swift build -c release --product meowpass_combined 2>/dev/null || {
    echo "Building with swiftc directly... 🛠️"
    echo "🧤 Kitten Mittens backup plan activated! 🧤"
    swiftc -O -o meowpass meowpass_combined.swift
}

# Step 4: Test the executable
echo "Testing the meow executable... 🧪"
echo "🧤 Kitten Mittens quality assurance testing! 🧤"
if [ -f "meowpass" ]; then
    echo "✅ Build successful! Testing... 🎉"
    echo "🧤 Kitten Mittens approved success! 🧤"
    ./meowpass --test
    echo ""
    echo "🎉 MeowPassword built successfully! 🎊"
    echo "🧤 Kitten Mittens guarantees satisfaction! 🧤"
    echo "📋 Usage: 📖"
    echo "  ./meowpass           - Generate password 🔐"
    echo "  ./meowpass --test    - Run tests 🧪"
    echo "  ./meowpass --copy    - Generate and copy to clipboard 📋"
    echo ""
    echo "🧤 Remember: Kitten Mittens - You'll be smitten! 🧤"
else
    echo "❌ Build failed - executable not found 😿"
    echo "🧤 Even Kitten Mittens couldn't save this build! 🧤"
    exit 1
fi