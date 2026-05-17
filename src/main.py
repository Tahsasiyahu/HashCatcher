import sys
import os
import subprocess
from pathlib import Path

from PySide6.QtCore import Qt, QThread, Signal
from PySide6.QtGui import QFont
from PySide6.QtWidgets import (
    QApplication,
    QFileDialog,
    QHBoxLayout,
    QLabel,
    QMainWindow,
    QMessageBox,
    QPushButton,
    QProgressBar,
    QTableWidget,
    QTableWidgetItem,
    QTextEdit,
    QVBoxLayout,
    QWidget,
)


class ConversionWorker(QThread):
    log_signal = Signal(str)
    progress_signal = Signal(int)
    status_signal = Signal(int, str)

    def __init__(self, files):
        super().__init__()
        self.files = files

    def run(self):
        total = len(self.files)

        for index, file in enumerate(self.files):
            output = str(Path(file).with_suffix(".22000"))

            self.log_signal.emit(f"[INFO] Converting: {file}")
            self.status_signal.emit(index, "Converting")

            command = [
                "hcxpcapngtool",
                "-o",
                output,
                file,
            ]

            try:
                subprocess.run(command, check=True)

                self.log_signal.emit(
                    f"[SUCCESS] Generated: {output}"
                )

                self.status_signal.emit(index, "Completed")

            except Exception as e:
                self.log_signal.emit(
                    f"[ERROR] {str(e)}"
                )

                self.status_signal.emit(index, "Failed")

            progress = int(((index + 1) / total) * 100)
            self.progress_signal.emit(progress)


class HashCatcher(QMainWindow):
    def __init__(self):
        super().__init__()

        self.files = []

        self.setWindowTitle("HashCatcher v3")
        self.resize(1400, 900)

        self.setAcceptDrops(True)

        central = QWidget()
        self.setCentralWidget(central)

        layout = QVBoxLayout(central)

        self.setup_header(layout)
        self.setup_toolbar(layout)
        self.setup_table(layout)
        self.setup_progress(layout)
        self.setup_logs(layout)

        self.apply_theme()

    def setup_header(self, layout):
        title = QLabel("HashCatcher")
        title.setFont(QFont("Segoe UI", 28, QFont.Bold))
        title.setAlignment(Qt.AlignCenter)

        subtitle = QLabel(
            "Offline Wireless Capture Conversion for Hashcat"
        )
        subtitle.setAlignment(Qt.AlignCenter)

        layout.addWidget(title)
        layout.addWidget(subtitle)

    def setup_toolbar(self, layout):
        toolbar = QHBoxLayout()

        self.add_btn = QPushButton("Add Files")
        self.add_btn.clicked.connect(self.add_files)

        self.clear_btn = QPushButton("Clear")
        self.clear_btn.clicked.connect(self.clear_queue)

        self.convert_btn = QPushButton("Convert")
        self.convert_btn.clicked.connect(self.convert_files)

        toolbar.addWidget(self.add_btn)
        toolbar.addWidget(self.clear_btn)
        toolbar.addWidget(self.convert_btn)

        layout.addLayout(toolbar)

    def setup_table(self, layout):
        self.table = QTableWidget(0, 5)

        self.table.setHorizontalHeaderLabels([
            "File",
            "Type",
            "Size",
            "Status",
            "Output",
        ])

        layout.addWidget(self.table)

    def setup_progress(self, layout):
        self.progress = QProgressBar()
        self.progress.setValue(0)
        layout.addWidget(self.progress)

    def setup_logs(self, layout):
        self.logs = QTextEdit()
        self.logs.setReadOnly(True)
        self.logs.setMinimumHeight(220)

        layout.addWidget(self.logs)

    def apply_theme(self):
        self.setStyleSheet("""
            QMainWindow {
                background-color: #0f0a0d;
            }

            QWidget {
                background-color: #0f0a0d;
                color: #f5f5f5;
                font-family: Segoe UI;
                font-size: 11pt;
            }

            QPushButton {
                background-color: #c2185b;
                border-radius: 10px;
                padding: 12px;
                color: white;
                font-weight: bold;
            }

            QPushButton:hover {
                background-color: #ff4d7a;
            }

            QTableWidget {
                background-color: #140b10;
                border: 1px solid #2b1620;
                border-radius: 10px;
                gridline-color: #2b1620;
            }

            QTextEdit {
                background-color: #140b10;
                border: 1px solid #2b1620;
                border-radius: 10px;
            }

            QProgressBar {
                border-radius: 8px;
                background-color: #241019;
                height: 16px;
            }

            QProgressBar::chunk {
                background-color: #ff4d7a;
                border-radius: 8px;
            }
        """)

    def add_log(self, message):
        self.logs.append(message)

    def add_files(self):
        files, _ = QFileDialog.getOpenFileNames(
            self,
            "Select Capture Files",
            "",
            "Capture Files (*.cap *.pcap *.pcapng)",
        )

        for file in files:
            if file not in self.files:
                self.files.append(file)
                self.add_file_to_table(file)

    def add_file_to_table(self, file):
        row = self.table.rowCount()
        self.table.insertRow(row)

        file_path = Path(file)

        size = round(os.path.getsize(file) / 1024 / 1024, 2)

        self.table.setItem(row, 0, QTableWidgetItem(file_path.name))
        self.table.setItem(row, 1, QTableWidgetItem(file_path.suffix))
        self.table.setItem(row, 2, QTableWidgetItem(f"{size} MB"))
        self.table.setItem(row, 3, QTableWidgetItem("Queued"))
        self.table.setItem(
            row,
            4,
            QTableWidgetItem(str(file_path.with_suffix(".22000"))),
        )

    def clear_queue(self):
        self.files.clear()
        self.table.setRowCount(0)
        self.logs.clear()
        self.progress.setValue(0)

    def convert_files(self):
        if not self.files:
            QMessageBox.warning(
                self,
                "No Files",
                "Please add capture files.",
            )
            return

        if not self.check_hcxtools():
            QMessageBox.critical(
                self,
                "hcxtools Missing",
                "hcxpcapngtool was not found.",
            )
            return

        self.worker = ConversionWorker(self.files)

        self.worker.log_signal.connect(self.add_log)
        self.worker.progress_signal.connect(self.progress.setValue)
        self.worker.status_signal.connect(self.update_status)

        self.worker.start()

    def update_status(self, row, status):
        self.table.setItem(row, 3, QTableWidgetItem(status))

    def check_hcxtools(self):
        try:
            subprocess.run(
                ["hcxpcapngtool", "--help"],
                stdout=subprocess.DEVNULL,
                stderr=subprocess.DEVNULL,
            )
            return True

        except Exception:
            return False

    def dragEnterEvent(self, event):
        if event.mimeData().hasUrls():
            event.acceptProposedAction()

    def dropEvent(self, event):
        for url in event.mimeData().urls():
            file = url.toLocalFile()

            if file.endswith((".cap", ".pcap", ".pcapng")):
                if file not in self.files:
                    self.files.append(file)
                    self.add_file_to_table(file)


if __name__ == "__main__":
    app = QApplication(sys.argv)

    window = HashCatcher()
    window.show()

    sys.exit(app.exec())
