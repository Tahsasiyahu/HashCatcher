#!/bin/bash

rm -rf package
mkdir -p package/DEBIAN
mkdir -p package/usr/local/bin

cp dist/HashCatcher package/usr/local/bin/hashcatcher
chmod +x package/usr/local/bin/hashcatcher

cat > package/DEBIAN/control <<EOF
Package: hashcatcher
Version: 1.0.0
Section: utils
Priority: optional
Architecture: amd64
Maintainer: Tahsasiyahu
Description: Offline wireless capture conversion utility
EOF

dpkg-deb --build package

mv package.deb HashCatcher_1.0.0_amd64.deb
