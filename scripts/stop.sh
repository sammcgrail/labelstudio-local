#!/bin/bash

echo "=== Stopping Label Studio Services ==="

echo "Stopping Label Studio..."
pkill -f "label-studio" 2>/dev/null || echo "Label Studio not running"

echo "Stopping Tesseract..."
podman stop tesseract 2>/dev/null || echo "Tesseract not running"

echo "Stopping YOLOv8..."
pkill -f "gunicorn.*9091" 2>/dev/null || echo "YOLO not running"

echo "Stopping EasyOCR..."
podman stop easyocr 2>/dev/null || echo "EasyOCR not running"

echo "Stopping MobileSAM..."
pkill -f "gunicorn.*9093" 2>/dev/null || echo "MobileSAM not running"

echo "All services stopped."
