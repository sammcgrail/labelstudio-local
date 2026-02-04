#!/bin/bash

echo "=== Stopping Label Studio Services ==="

echo "Stopping Label Studio..."
pkill -f "label-studio" 2>/dev/null || echo "Label Studio not running"

echo "Stopping Tesseract..."
podman stop tesseract 2>/dev/null || echo "Tesseract not running"

echo "Stopping YOLOv8..."
pkill -f "gunicorn.*9091" 2>/dev/null || echo "YOLO not running"

echo "All services stopped."
