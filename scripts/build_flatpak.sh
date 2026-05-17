#!/bin/bash

set -e

flatpak-builder build-dir io.hashcatcher.HashCatcher.json

flatpak build-export repo build-dir

flatpak build-bundle repo hashcatcher.flatpak \
    io.hashcatcher.HashCatcher

echo "✅ Flatpak build complete"
