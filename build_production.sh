#!/bin/bash
# Production build script for MeowPassword
# Creates a practical deployable version with 1000+ cat names

set -e

echo "🐾 MeowPassword Production Build"
echo "================================"

# Clean previous builds
rm -f meowpass embedded_production.swift

# Step 1: Create manageable embedded dataset (first 1000 names)
echo "📝 Creating production embedded dataset (1000 cat names)..."
echo "// MARK: - Embedded Cat Names Data (Production)" > embedded_production.swift
echo "let embeddedCatNames: [String] = [" >> embedded_production.swift

# Add first 1000 cat names with proper Swift string escaping
head -1000 catNamesText.txt | while IFS= read -r line; do
    # Escape quotes and backslashes for Swift
    escaped_line=$(echo "$line" | sed 's/\\/\\\\/g' | sed 's/"/\\"/g')
    echo "    \"$escaped_line\"," >> embedded_production.swift
done

echo "]" >> embedded_production.swift

# Step 2: Create combined file
echo "🔧 Combining source files..."
cat embedded_production.swift > meowpass_production.swift
echo "" >> meowpass_production.swift
cat main.swift >> meowpass_production.swift

# Step 3: Compile
echo "⚙️  Compiling production executable..."
if swiftc -O -o meowpass meowpass_production.swift; then
    echo "✅ Production build successful (optimized)!"
elif swiftc -o meowpass meowpass_production.swift; then
    echo "✅ Production build successful (debug)!"
else
    echo "❌ Production build failed"
    exit 1
fi

# Step 4: Test
if [ -f "meowpass" ]; then
    echo ""
    echo "📊 Build Statistics:"
    echo "   Executable size: $(ls -lh meowpass | awk '{print $5}')"
    echo "   Cat names count: 1000"
    echo ""
    
    echo "🧪 Running quick test..."
    timeout 20 ./meowpass --test | head -15
    
    echo ""
    echo "🎉 MeowPassword Production Build Complete!"
    echo ""
    echo "📋 Usage:"
    echo "   ./meowpass           - Generate secure password"
    echo "   ./meowpass --test    - Run tests"
    echo "   ./meowpass --copy    - Copy to clipboard (macOS)"
    echo ""
    echo "📦 To install system-wide:"
    echo "   sudo cp meowpass /usr/local/bin/"
    echo "   sudo chmod +x /usr/local/bin/meowpass"
    echo ""
    echo "Then you can run 'meowpass' from anywhere! 🎊"
    
else
    echo "❌ Build failed - executable not created"
    exit 1
fi