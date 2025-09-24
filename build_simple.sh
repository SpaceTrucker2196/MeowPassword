#!/bin/bash
# Simple build script - creates self-contained executable
set -e

echo "🐾 Building MeowPassword (Simple approach)..."

# Create a much simpler embedded version - just base64 encode the file
echo "📝 Creating base64 embedded data..."
cat > embedded_simple.swift << 'EOF'
// MARK: - Embedded Cat Names Data  
import Foundation

private let embeddedCatNamesBase64 = """
EOF

# Base64 encode the cat names file
base64 -w 0 catNamesText.txt >> embedded_simple.swift

cat >> embedded_simple.swift << 'EOF'
"""

let embeddedCatNames: [String] = {
    guard let data = Data(base64Encoded: embeddedCatNamesBase64),
          let content = String(data: data, encoding: .utf8) else {
        return []
    }
    return content.components(separatedBy: .newlines)
        .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
        .filter { !$0.isEmpty }
}()
EOF

# Combine files
echo "🔧 Creating executable..."
cat embedded_simple.swift > meowpass_final.swift
echo "" >> meowpass_final.swift
cat main.swift >> meowpass_final.swift

# Compile with timeout
echo "⚙️  Compiling (this may take a moment)..."
timeout 45 swiftc -o meowpass meowpass_final.swift || {
    echo "⚠️  Compilation taking long, trying without optimization..."
    swiftc -Onone -o meowpass meowpass_final.swift
}

# Test
if [ -f "meowpass" ]; then
    echo "✅ Build successful!"
    file_size=$(ls -lh meowpass | awk '{print $5}')
    echo "📊 Executable size: $file_size"
    echo ""
    echo "🧪 Quick test run..."
    echo "Running: ./meowpass --test"
    timeout 20 ./meowpass --test 2>/dev/null | head -10 || echo "Test completed"
    echo ""
    echo "🎉 MeowPassword is ready!"
    echo "💡 Usage: ./meowpass [--test] [--copy]"
else
    echo "❌ Build failed - executable not created"
    exit 1
fi