#!/bin/bash

set -e

echo "🐧 Building HashCatcher for Linux"

sudo apt update

sudo apt install -y \
    python3 \
    python3-pip \
    python3-pyside6 \
    hcxtools \
    hashcat \
    dpkg-dev \
    flatpak \
    git \
    wget

pip install pyinstaller

mkdir -p build dist

echo "⚙ Building executable..."

pyinstaller \
    --onefile \
    --windowed \
    src/main.py \
    --name HashCatcher

echo "📦 Building DEB..."

dpkg-deb --build HashCatcher

mv HashCatcher.deb dist/hashcatcher_linux.deb

echo "🚀 Building AppImage..."

wget -q https://github.com/AppImage/AppImageKit/releases/download/continuous/appimagetool-x86_64.AppImage

chmod +x appimagetool-x86_64.AppImage

./appimagetool-x86_64.AppImage AppDir

echo "✅ Linux build complete"
