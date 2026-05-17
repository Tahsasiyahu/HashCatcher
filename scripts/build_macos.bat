#!/bin/bash

set -e

echo "🍎 Building HashCatcher for macOS"

brew install python

pip3 install pyinstaller

mkdir -p dist

pyinstaller \
    --onefile \
    --windowed \
    src/main.py \
    --name HashCatcher

echo "📦 Creating DMG..."

hdiutil create \
  -volname HashCatcher \
  -srcfolder dist \
  -ov \
  -format UDZO \
  HashCatcher.dmg

echo "✅ macOS build complete"
