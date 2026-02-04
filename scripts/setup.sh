#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"
YOLO_DIR="$ROOT_DIR/label-studio-ml-backend/label_studio_ml/examples/yolo"

cd "$ROOT_DIR"

echo "=== Label Studio Local Setup ==="
echo "Root directory: $ROOT_DIR"

# Detect OS
OS="$(uname -s)"
echo "Detected OS: $OS"

# Check for uv
if ! command -v uv &> /dev/null; then
    echo "Installing uv..."
    curl -LsSf https://astral.sh/uv/install.sh | sh
    export PATH="$HOME/.local/bin:$PATH"
fi

# Check for podman
if ! command -v podman &> /dev/null; then
    echo "ERROR: Podman is not installed."
    echo "Install from: https://podman.io/docs/installation"
    exit 1
fi

echo ""
echo "=== Setting up Label Studio ==="
uv venv .venv
source .venv/bin/activate
uv pip install label-studio

echo ""
echo "=== Setting up Tesseract OCR Backend ==="
mkdir -p data/tesseract
podman pull docker.io/heartexlabs/label-studio-ml-backend:tesseract-master

# Remove existing container if exists
podman rm -f tesseract 2>/dev/null || true

if [ "$OS" = "Darwin" ]; then
    # macOS: use port mapping
    podman run -d \
        --name tesseract \
        -p 9090:9090 \
        -e LOG_LEVEL=DEBUG \
        -e LABEL_STUDIO_HOST=http://host.containers.internal:8080 \
        -v "$ROOT_DIR/data/tesseract:/data:Z" \
        docker.io/heartexlabs/label-studio-ml-backend:tesseract-master
else
    # Linux/WSL: use host networking
    podman run -d \
        --name tesseract \
        --network=host \
        -e LOG_LEVEL=DEBUG \
        -e LABEL_STUDIO_HOST=http://localhost:8080 \
        -v "$ROOT_DIR/data/tesseract:/data:Z" \
        docker.io/heartexlabs/label-studio-ml-backend:tesseract-master
fi

echo ""
echo "=== Setting up YOLOv8 Backend ==="
cd "$YOLO_DIR"

uv venv .venv
source .venv/bin/activate

uv pip install \
    gunicorn \
    ultralytics \
    tqdm \
    "torchmetrics<1.8.0" \
    "label-studio-ml @ git+https://github.com/HumanSignal/label-studio-ml-backend.git@master" \
    "label-studio-sdk @ git+https://github.com/HumanSignal/label-studio-sdk.git"

mkdir -p data/server models cache_dir

cd "$ROOT_DIR"

# Stop tesseract for now (will be started with start.sh)
podman stop tesseract 2>/dev/null || true

echo ""
echo "=== Setup Complete ==="
echo ""
echo "Run ./scripts/start.sh to start all services"
echo ""
echo "Services will be available at:"
echo "  - Label Studio: http://localhost:8080"
echo "  - Tesseract:    http://localhost:9090"
echo "  - YOLOv8:       http://localhost:9091"
