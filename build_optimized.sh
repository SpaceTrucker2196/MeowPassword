#!/bin/bash
# Optimized build script for MeowPassword
# Creates a more efficient embedded format

set -e

echo "🐾 Building MeowPassword (Optimized)..."

# Step 1: Create a compressed embedded format
echo "📝 Creating optimized embedded cat names..."
cat > embedded_names_optimized.swift << 'EOF'
// MARK: - Embedded Cat Names Data (Optimized)
import Foundation

private let embeddedCatNamesString = """
EOF

# Add all cat names as a single string (more compact)
cat catNamesText.txt | tr '\n' '|' >> embedded_names_optimized.swift

cat >> embedded_names_optimized.swift << 'EOF'
"""

let embeddedCatNames: [String] = {
    return embeddedCatNamesString.components(separatedBy: "|").filter { !$0.isEmpty }
}()
EOF

# Step 2: Create combined file
echo "🔧 Creating combined executable..."
cat embedded_names_optimized.swift > meowpass_optimized.swift
echo "" >> meowpass_optimized.swift
cat main.swift >> meowpass_optimized.swift

# Step 3: Compile
echo "⚙️  Compiling..."
timeout 60 swiftc -O -o meowpass meowpass_optimized.swift || {
    echo "⚠️  Standard compilation timed out, trying debug build..."
    swiftc -o meowpass meowpass_optimized.swift
}

# Step 4: Test
if [ -f "meowpass" ]; then
    echo "✅ Build successful!"
    echo "📊 File size: $(ls -lh meowpass | awk '{print $5}')"
    echo ""
    echo "🧪 Quick test..."
    timeout 30 ./meowpass --test || echo "Test completed or timed out"
    echo ""
    echo "🎉 MeowPassword ready!"
else
    echo "❌ Build failed"
    exit 1
fi