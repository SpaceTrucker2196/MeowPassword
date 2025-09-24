#!/bin/bash
# Install script for MeowPassword
# Installs meowpass as a system command

set -e

echo "🐾 MeowPassword Installer"
echo "========================"

# Check if we need to build first
if [ ! -f "meowpass" ]; then
    echo "📦 Building MeowPassword first..."
    if [ -f "build_production.sh" ]; then
        chmod +x build_production.sh
        ./build_production.sh
    else
        echo "❌ Build script not found. Please run build_production.sh first."
        exit 1
    fi
fi

# Determine installation directory
if [ -w "/usr/local/bin" ] || [ "$(id -u)" -eq 0 ]; then
    INSTALL_DIR="/usr/local/bin"
elif [ -w "$HOME/.local/bin" ]; then
    INSTALL_DIR="$HOME/.local/bin"
    mkdir -p "$INSTALL_DIR"
else
    INSTALL_DIR="$HOME/bin"
    mkdir -p "$INSTALL_DIR"
fi

echo "📂 Installing to: $INSTALL_DIR"

# Copy executable
cp meowpass "$INSTALL_DIR/meowpass"
chmod +x "$INSTALL_DIR/meowpass"

echo "✅ MeowPassword installed successfully!"

# Check if directory is in PATH
if echo "$PATH" | grep -q "$INSTALL_DIR"; then
    echo "🎉 You can now run 'meowpass' from anywhere!"
else
    echo "⚠️  Note: $INSTALL_DIR is not in your PATH"
    echo "💡 Add this to your ~/.bashrc or ~/.zshrc:"
    echo "   export PATH=\"$INSTALL_DIR:\$PATH\""
    echo ""
    echo "Or run the command directly:"
    echo "   $INSTALL_DIR/meowpass"
fi

echo ""
echo "📋 Usage:"
echo "   meowpass           - Generate secure password"
echo "   meowpass --test    - Run tests"
echo "   meowpass --copy    - Copy to clipboard (macOS)"
echo ""
echo "🐾 Happy password generating!"