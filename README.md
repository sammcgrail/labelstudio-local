# Label Studio with ML Backends Setup Guide

This guide covers setting up Label Studio with Tesseract OCR and YOLOv8 ML backends on Ubuntu/WSL.

## Prerequisites

- Python 3.12+
- [uv](https://github.com/astral-sh/uv) (Python package manager)
- Podman (for Tesseract container)

## Directory Structure

```
labeltest/
├── .venv/                          # Label Studio virtual environment
├── label-studio-ml-backend/        # ML backend repository
│   └── label_studio_ml/
│       └── examples/
│           ├── tesseract/          # Tesseract OCR backend
│           └── yolo/               # YOLOv8 backend
│               └── .venv-yolo/     # YOLO virtual environment
└── SETUP.md
```

## Installation

### 1. Set Up Label Studio

```bash
# Create project directory
mkdir labeltest && cd labeltest

# Set Python version (if using pyenv)
pyenv local 3.12.0

# Create virtual environment and install Label Studio
uv venv
source .venv/bin/activate
uv pip install label-studio
```

### 2. Clone ML Backend Repository

```bash
git clone https://github.com/HumanSignal/label-studio-ml-backend.git
```

### 3. Set Up Tesseract OCR Backend (using Podman)

```bash
# Pull the pre-built image
podman pull docker.io/heartexlabs/label-studio-ml-backend:tesseract-master

# Create data directory
mkdir -p label-studio-ml-backend/label_studio_ml/examples/tesseract/data/server

# Run the container with host networking
podman run -d --name tesseract --network=host \
  -e LOG_LEVEL=DEBUG \
  -e LABEL_STUDIO_HOST=http://localhost:8080 \
  -e LABEL_STUDIO_ACCESS_TOKEN= \
  -v $(pwd)/label-studio-ml-backend/label_studio_ml/examples/tesseract/data/server:/data:Z \
  docker.io/heartexlabs/label-studio-ml-backend:tesseract-master
```

### 4. Set Up YOLOv8 Backend (native Python)

The YOLO backend runs natively without containers for better compatibility (avoids CUDA requirements in WSL).

```bash
cd label-studio-ml-backend/label_studio_ml/examples/yolo

# Create separate virtual environment for YOLO
uv venv .venv-yolo
source .venv-yolo/bin/activate

# Install dependencies
uv pip install gunicorn ultralytics tqdm "torchmetrics<1.8.0" \
  "label-studio-ml @ git+https://github.com/HumanSignal/label-studio-ml-backend.git@master" \
  "label-studio-sdk @ git+https://github.com/HumanSignal/label-studio-sdk.git"

# Create necessary directories
mkdir -p data/server models cache_dir
```

## Running the Services

### Start Label Studio (port 8080)

```bash
cd ~/labeltest
source .venv/bin/activate
label-studio start --port 8080
```

Access at: http://localhost:8080

### Start Tesseract OCR Backend (port 9090)

```bash
podman start tesseract
```

Health check: `curl http://localhost:9090/health`

### Start YOLOv8 Backend (port 9091)

```bash
cd ~/labeltest/label-studio-ml-backend/label_studio_ml/examples/yolo
source .venv-yolo/bin/activate
LABEL_STUDIO_HOST=http://localhost:8080 \
PYTHONPATH=$(pwd) \
PORT=9091 \
gunicorn --bind :9091 --workers 1 --threads 4 --timeout 0 _wsgi:app
```

Health check: `curl http://localhost:9091/health`

## Connecting ML Backends to Label Studio

1. Open Label Studio at http://localhost:8080
2. Create or open a project
3. Go to **Settings** → **Model**
4. Click **Connect Model**
5. Enter the backend URL:
   - Tesseract: `http://localhost:9090`
   - YOLO: `http://localhost:9091`
6. Enable **Interactive preannotations**
7. Save

## Labeling Configurations

### Tesseract OCR (Text Recognition)

```xml
<View>
  <Image name="image" value="$ocr" zoom="true" zoomControl="false"
         rotateControl="true" width="100%" height="100%"
         maxHeight="auto" maxWidth="auto"/>
  <RectangleLabels name="bbox" toName="image" strokeWidth="1" smart="true">
    <Label value="Text" background="green"/>
  </RectangleLabels>
  <TextArea name="transcription" toName="image" editable="true"
            perRegion="true" required="false" maxSubmissions="1"
            rows="5" placeholder="Recognized Text"
            displayMode="region-list"/>
</View>
```

### YOLOv8 Object Detection

```xml
<View>
  <Image name="image" value="$image"/>
  <RectangleLabels name="label" toName="image">
    <Label value="person" background="red"/>
    <Label value="car" background="blue"/>
    <Label value="truck" background="green"/>
    <Label value="dog" background="orange"/>
    <Label value="cat" background="purple"/>
  </RectangleLabels>
</View>
```

YOLO supports 80 COCO classes: person, bicycle, car, motorcycle, airplane, bus, train, truck, boat, traffic light, fire hydrant, stop sign, parking meter, bench, bird, cat, dog, horse, sheep, cow, elephant, bear, zebra, giraffe, backpack, umbrella, handbag, tie, suitcase, frisbee, skis, snowboard, sports ball, kite, baseball bat, baseball glove, skateboard, surfboard, tennis racket, bottle, wine glass, cup, fork, knife, spoon, bowl, banana, apple, sandwich, orange, broccoli, carrot, hot dog, pizza, donut, cake, chair, couch, potted plant, bed, dining table, toilet, tv, laptop, mouse, remote, keyboard, cell phone, microwave, oven, toaster, sink, refrigerator, book, clock, vase, scissors, teddy bear, hair drier, toothbrush.

## Service Summary

| Service | Port | Type | URL |
|---------|------|------|-----|
| Label Studio | 8080 | Web UI | http://localhost:8080 |
| Tesseract OCR | 9090 | Container (Podman) | http://localhost:9090 |
| YOLOv8 | 9091 | Native Python | http://localhost:9091 |

## Troubleshooting

### Label Studio slow to start
First startup can take 1-2 minutes as it initializes the database and checks for updates.

### Podman container not starting
```bash
# Check container status
podman ps -a

# View logs
podman logs tesseract

# Remove and recreate if needed
podman rm tesseract
# Then run the podman run command again
```

### YOLO model downloads
On first run, YOLO will download model weights (~50-100MB). This is normal.

### WSL networking
In WSL2, `localhost` forwarding to Windows usually works automatically. If not, use the WSL IP:
```bash
hostname -I | awk '{print $1}'
```

## Stopping Services

```bash
# Label Studio: Ctrl+C in terminal or
pkill -f "label-studio"

# Tesseract
podman stop tesseract

# YOLO: Ctrl+C in terminal or
pkill -f "gunicorn.*9091"
```
