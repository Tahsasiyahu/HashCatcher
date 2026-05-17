#!/bin/bash

set -e

echo "======================================"
echo "🐾 HashCatcher Full Setup Script"
echo "======================================"

PROJECT="HashCatcher"
VERSION="1.0.0"

echo ""
echo "[1/10] Installing dependencies..."

sudo apt update

sudo apt install -y \
    python3 \
    python3-pip \
    python3-pyside6 \
    hcxtools \
    hashcat \
    dpkg-dev \
    git \
    desktop-file-utils

echo ""
echo "[2/10] Creating project structure..."

mkdir -p $PROJECT

cd $PROJECT

mkdir -p \
    src \
    assets \
    scripts \
    DEBIAN \
    usr/bin \
    usr/share/applications \
    usr/share/hashcatcher

mkdir -p dist

echo ""
echo "[3/10] Writing Python source files..."

cat > src/main.py << 'EOF'
import sys
from PySide6.QtWidgets import QApplication
from gui import MainWindow

app = QApplication(sys.argv)

window = MainWindow()
window.show()

sys.exit(app.exec())
EOF

cat > src/gui.py << 'EOF'
from PySide6.QtWidgets import (
    QWidget, QVBoxLayout, QPushButton,
    QListWidget, QLabel, QFileDialog,
    QListWidgetItem, QProgressBar
)

from PySide6.QtCore import Qt, QThreadPool
from worker import ConvertTask

class MainWindow(QWidget):

    def __init__(self):
        super().__init__()

        self.setWindowTitle("HashCatcher")
        self.setMinimumSize(900, 600)
        self.setAcceptDrops(True)

        self.pool = QThreadPool.globalInstance()
        self.pool.setMaxThreadCount(2)

        self.queue = []

        layout = QVBoxLayout()

        self.label = QLabel("Drop capture files here")
        self.label.setAlignment(Qt.AlignCenter)
        self.label.setStyleSheet(
            "border:2px dashed #555;padding:40px;"
        )

        self.list_widget = QListWidget()

        self.add_btn = QPushButton("Add Files")
        self.convert_btn = QPushButton("Convert")

        self.add_btn.clicked.connect(self.add_files)
        self.convert_btn.clicked.connect(self.start_queue)

        layout.addWidget(self.label)
        layout.addWidget(self.list_widget)
        layout.addWidget(self.add_btn)
        layout.addWidget(self.convert_btn)

        self.setLayout(layout)

    def dragEnterEvent(self, event):
        if event.mimeData().hasUrls():
            event.accept()

    def dropEvent(self, event):
        for url in event.mimeData().urls():
            self.add_file(url.toLocalFile())

    def add_files(self):

        files, _ = QFileDialog.getOpenFileNames(
            self,
            "Select Capture Files",
            "",
            "Captures (*.cap *.pcap *.pcapng)"
        )

        for file in files:
            self.add_file(file)

    def add_file(self, path):

        item = QListWidgetItem(path)

        progress = QProgressBar()
        progress.setValue(0)

        self.list_widget.addItem(item)
        self.list_widget.setItemWidget(item, progress)

        self.queue.append((path, progress))

    def start_queue(self):

        for path, progress in self.queue:
            task = ConvertTask(path, progress)
            self.pool.start(task)
EOF

cat > src/worker.py << 'EOF'
from PySide6.QtCore import QRunnable
import subprocess
import os

class ConvertTask(QRunnable):

    def __init__(self, file_path, progress_bar):
        super().__init__()

        self.file_path = file_path
        self.progress_bar = progress_bar

    def run(self):

        try:

            os.makedirs("output", exist_ok=True)

            output_file = os.path.join(
                "output",
                os.path.basename(self.file_path) + ".22000"
            )

            self.progress_bar.setValue(20)

            process = subprocess.Popen([
                "hcxpcapngtool",
                "-o",
                output_file,
                self.file_path
            ])

            self.progress_bar.setValue(50)

            process.wait()

            self.progress_bar.setValue(100)

        except Exception:
            self.progress_bar.setValue(0)
EOF

echo ""
echo "[4/10] Creating launcher..."

cat > usr/bin/hashcatcher << 'EOF'
#!/bin/bash
python3 /usr/share/hashcatcher/src/main.py
EOF

chmod +x usr/bin/hashcatcher

echo ""
echo "[5/10] Creating desktop file..."

cat > usr/share/applications/hashcatcher.desktop << 'EOF'
[Desktop Entry]
Name=HashCatcher
Exec=hashcatcher
Icon=hashcatcher
Type=Application
Categories=Utility;
EOF

echo ""
echo "[6/10] Creating DEBIAN metadata..."

cat > DEBIAN/control << EOF
Package: hashcatcher
Version: $VERSION
Section: utils
Priority: optional
Architecture: all
Depends: python3, python3-pyside6, hcxtools, hashcat
Maintainer: Tahsasiyahu
Description: Offline wireless capture converter for Hashcat workflows
EOF

cat > DEBIAN/postinst << 'EOF'
#!/bin/bash
update-desktop-database || true
EOF

chmod 755 DEBIAN/postinst

echo ""
echo "[7/10] Copying source files..."

cp -r src usr/share/hashcatcher/

echo ""
echo "[8/10] Building .deb package..."

dpkg-deb --build $PROJECT

mv ${PROJECT}.deb dist/hashcatcher_${VERSION}.deb

echo ""
echo "[9/10] Initializing Git repository..."

git init

git add .

git commit -m "Initial HashCatcher release"

echo ""
echo "[10/10] DONE"

echo ""
echo "======================================"
echo "✅ Build Complete"
echo "======================================"

echo ""
echo "📦 Package:"
echo "dist/hashcatcher_${VERSION}.deb"

echo ""
echo "🚀 Install with:"
echo "sudo dpkg -i dist/hashcatcher_${VERSION}.deb"

echo ""
echo "🐾 HashCatcher ready."
