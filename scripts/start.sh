#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"
YOLO_DIR="$ROOT_DIR/label-studio-ml-backend/label_studio_ml/examples/yolo"

cd "$ROOT_DIR"

echo "=== Starting Label Studio Services ==="

# Start Tesseract container
echo "Starting Tesseract OCR (port 9090)..."
podman start tesseract 2>/dev/null || echo "Warning: Tesseract container not found. Run ./scripts/setup.sh first."

# Start YOLO backend in background
echo "Starting YOLOv8 (port 9091)..."
cd "$YOLO_DIR"
source .venv/bin/activate

LABEL_STUDIO_HOST=http://localhost:8080 \
PYTHONPATH="$YOLO_DIR" \
gunicorn --bind :9091 --workers 1 --threads 4 --timeout 0 _wsgi:app &
YOLO_PID=$!
echo "YOLO started (PID: $YOLO_PID)"

cd "$ROOT_DIR"

# Wait for backends to be ready
sleep 3

# Start Label Studio in foreground
echo "Starting Label Studio (port 8080)..."
echo "Press Ctrl+C to stop all services"
source .venv/bin/activate
label-studio start --port 8080
