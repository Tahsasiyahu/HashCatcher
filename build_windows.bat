@echo off

echo 🪟 Building HashCatcher for Windows

python -m pip install pyinstaller

pyinstaller ^
 --onefile ^
 --windowed ^
 --name HashCatcher ^
 src/main.py

echo ✅ Windows build complete

pause
