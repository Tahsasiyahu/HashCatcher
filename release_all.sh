#!/bin/bash

set -e

echo "🚀 HashCatcher Universal Release Builder"

chmod +x \
    build_linux.sh \
    build_macos.sh \
    build_flatpak.sh

echo ""
echo "🐧 Linux..."
./build_linux.sh

echo ""
echo "🍎 macOS..."
./build_macos.sh

echo ""
echo "📦 Flatpak..."
./build_flatpak.sh

echo ""
echo "✅ ALL BUILDS COMPLETE"
