# Label Studio with ML Backends - Manual Setup Guide

This guide covers manual setup of Label Studio with Tesseract OCR and YOLOv8 ML backends on Linux/WSL or macOS.

> **Note:** For automated setup, use `make setup` instead. See [README.md](README.md).

## Prerequisites

- Python 3.12+
- [uv](https://docs.astral.sh/uv/getting-started/installation/) - `curl -LsSf https://astral.sh/uv/install.sh | sh`
- [Podman](https://podman.io/docs/installation) - container runtime

## Directory Structure

```
labelstudio-local/
├── .venv/                          # Label Studio virtual environment
├── Makefile                        # Automated setup/run commands
├── README.md
├── SETUP.md                        # This file
├── data/                           # Runtime data (gitignored)
│   └── tesseract/
└── label-studio-ml-backend/        # ML backend code (included in repo)
    └── label_studio_ml/
        └── examples/
            ├── tesseract/
            └── yolo/
                └── .venv/          # YOLO virtual environment
```

## Manual Installation

All commands assume you are in the `labelstudio-local` directory.

### 1. Set Up Label Studio

```bash
cd labelstudio-local

uv venv .venv
source .venv/bin/activate
uv pip install label-studio
```

### 2. Set Up Tesseract OCR Backend (Podman)

```bash
# Pull the pre-built image
podman pull docker.io/heartexlabs/label-studio-ml-backend:tesseract-master

# Create data directory
mkdir -p data/tesseract

# Linux/WSL: Run with host networking
podman run -d --name tesseract --network=host \
  -e LOG_LEVEL=DEBUG \
  -e LABEL_STUDIO_HOST=http://localhost:8080 \
  -v $(pwd)/data/tesseract:/data:Z \
  docker.io/heartexlabs/label-studio-ml-backend:tesseract-master

# macOS: Run with port mapping (host networking not supported)
podman run -d --name tesseract \
  -p 9090:9090 \
  -e LOG_LEVEL=DEBUG \
  -e LABEL_STUDIO_HOST=http://host.containers.internal:8080 \
  -v $(pwd)/data/tesseract:/data:Z \
  docker.io/heartexlabs/label-studio-ml-backend:tesseract-master
```

### 3. Set Up YOLOv8 Backend (Native Python)

```bash
cd label-studio-ml-backend/label_studio_ml/examples/yolo

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

cd ../../../..  # Back to labelstudio-local root
```

## Running Services Manually

All commands assume you are in the `labelstudio-local` directory.

### Start Label Studio (port 8080)

```bash
source .venv/bin/activate
label-studio start --port 8080
```

### Start Tesseract OCR Backend (port 9090)

```bash
podman start tesseract
```

### Start YOLOv8 Backend (port 9091)

```bash
cd label-studio-ml-backend/label_studio_ml/examples/yolo
source .venv/bin/activate
LABEL_STUDIO_HOST=http://localhost:8080 \
PYTHONPATH=$(pwd) \
gunicorn --bind :9091 --workers 1 --threads 4 --timeout 0 _wsgi:app
```

## Health Checks

```bash
curl http://localhost:8080        # Label Studio (302 = OK)
curl http://localhost:9090/health # Tesseract ({"status":"UP"})
curl http://localhost:9091/health # YOLO ({"status":"UP"})
```

## Stopping Services

```bash
pkill -f "label-studio"
podman stop tesseract
pkill -f "gunicorn.*9091"
```

## Connecting ML Backends to Label Studio

1. Open http://localhost:8080
2. Create or open a project
3. Go to **Settings** → **Model**
4. Click **Connect Model**
5. Enter URL: `http://localhost:9090` (Tesseract) or `http://localhost:9091` (YOLO)
6. Enable **Interactive preannotations**
7. Save

## Labeling Configurations

### Tesseract OCR

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
  </RectangleLabels>
</View>
```

## YOLO Classes

YOLOv8 supports 80 COCO classes: person, bicycle, car, motorcycle, airplane, bus, train, truck, boat, traffic light, fire hydrant, stop sign, parking meter, bench, bird, cat, dog, horse, sheep, cow, elephant, bear, zebra, giraffe, backpack, umbrella, handbag, tie, suitcase, frisbee, skis, snowboard, sports ball, kite, baseball bat, baseball glove, skateboard, surfboard, tennis racket, bottle, wine glass, cup, fork, knife, spoon, bowl, banana, apple, sandwich, orange, broccoli, carrot, hot dog, pizza, donut, cake, chair, couch, potted plant, bed, dining table, toilet, tv, laptop, mouse, remote, keyboard, cell phone, microwave, oven, toaster, sink, refrigerator, book, clock, vase, scissors, teddy bear, hair drier, toothbrush.

## Troubleshooting

### Label Studio slow to start
First startup takes 1-2 minutes for database initialization.

### Podman container issues
```bash
podman ps -a          # Check status
podman logs tesseract # View logs
podman rm tesseract   # Remove and recreate
```

### YOLO model downloads
On first run, YOLO downloads model weights (~50-100MB). This is normal.

### WSL networking
In WSL2, localhost forwarding usually works. If not, get WSL IP:
```bash
hostname -I | awk '{print $1}'
```
