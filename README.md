# Label Studio Local Setup

Local Label Studio with Tesseract OCR and YOLO ML backends.

## Quick Start

### macOS

```bash
git clone https://github.com/sammcgrail/labelstudio-local.git
cd labelstudio-local
make setup
make start
```

### WSL/Linux

```bash
git clone https://github.com/sammcgrail/labelstudio-local.git
cd labelstudio-local
./scripts/setup.sh
./scripts/start.sh
```

## Requirements

- Python 3.12+
- [uv](https://docs.astral.sh/uv/getting-started/installation/) - `curl -LsSf https://astral.sh/uv/install.sh | sh`
- [Podman](https://podman.io/docs/installation)

## Services

| Service | Port | URL |
|---------|------|-----|
| Label Studio | 8080 | http://localhost:8080 |
| Tesseract OCR | 9090 | http://localhost:9090 |
| YOLO (v8/v11) | 9091 | http://localhost:9091 |

> **Note:** YOLO11n model (5.6MB) is included. Supports YOLO and YOLO11 models.

## Commands

### Make (macOS/Linux)

```bash
make setup     # Install everything
make start     # Start all services
make stop      # Stop all services
make health    # Check service status
make clean     # Remove installed components
make help      # Show all commands
```

### Bash Scripts (WSL/Linux)

```bash
./scripts/setup.sh   # Install everything
./scripts/start.sh   # Start all services
./scripts/stop.sh    # Stop all services
./scripts/health.sh  # Check service status
```

## Connecting ML Backends

1. Open http://localhost:8080
2. Create/open a project
3. Go to **Settings** → **Model**
4. Click **Connect Model**
5. Add URL: `http://localhost:9090` (Tesseract) or `http://localhost:9091` (YOLO)
6. Enable **Interactive preannotations**

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

### YOLO Object Detection (v8/v11)

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

**YOLO Classes (80 COCO):** person, bicycle, car, motorcycle, airplane, bus, train, truck, boat, traffic light, fire hydrant, stop sign, parking meter, bench, bird, cat, dog, horse, sheep, cow, elephant, bear, zebra, giraffe, backpack, umbrella, handbag, tie, suitcase, frisbee, skis, snowboard, sports ball, kite, baseball bat, baseball glove, skateboard, surfboard, tennis racket, bottle, wine glass, cup, fork, knife, spoon, bowl, banana, apple, sandwich, orange, broccoli, carrot, hot dog, pizza, donut, cake, chair, couch, potted plant, bed, dining table, toilet, tv, laptop, mouse, remote, keyboard, cell phone, microwave, oven, toaster, sink, refrigerator, book, clock, vase, scissors, teddy bear, hair drier, toothbrush.

## How YOLO Model Selection Works

The YOLO backend uses the [ultralytics](https://github.com/ultralytics/ultralytics) library, which supports multiple YOLO versions through a unified API. You specify which model to use via the `model_path` attribute in your labeling config.

### Included Model

- `yolo11n.pt` - YOLO11 nano (5.6MB, fastest) - **included in repo**

### Using Different Models

Add `model_path` to your `<RectangleLabels>` tag:

```xml
<!-- YOLO11 (default, included) -->
<RectangleLabels name="label" toName="image" model_path="yolo11n.pt">

<!-- YOLOv8 variants -->
<RectangleLabels name="label" toName="image" model_path="yolov8n.pt">
<RectangleLabels name="label" toName="image" model_path="yolov8s.pt">
<RectangleLabels name="label" toName="image" model_path="yolov8m.pt">

<!-- YOLO11 variants -->
<RectangleLabels name="label" toName="image" model_path="yolo11n.pt">
<RectangleLabels name="label" toName="image" model_path="yolo11s.pt">
<RectangleLabels name="label" toName="image" model_path="yolo11m.pt">
```

### Model Naming

| Version | Naming | Example |
|---------|--------|---------|
| YOLOv5 | `yolov5{size}u.pt` | `yolov5nu.pt` |
| YOLOv8 | `yolov8{size}.pt` | `yolov8n.pt` |
| YOLO11 | `yolo11{size}.pt` | `yolo11n.pt` (no "v"!) |

Sizes: `n` (nano), `s` (small), `m` (medium), `l` (large), `x` (xlarge)

### Task-Specific Models

```xml
<!-- Object Detection (default) -->
<RectangleLabels model_path="yolo11n.pt">

<!-- Segmentation -->
<PolygonLabels model_path="yolo11n-seg.pt">

<!-- Pose Estimation -->
<KeypointLabels model_path="yolo11n-pose.pt">

<!-- Classification -->
<Choices model_path="yolo11n-cls.pt">
```

Models are auto-downloaded on first use if not present in the `models/` directory.

---

## Manual Setup

All commands assume you're in the `labelstudio-local` directory.

### 1. Label Studio

```bash
uv venv .venv
source .venv/bin/activate
uv pip install label-studio
```

### 2. Tesseract (Podman)

```bash
podman pull docker.io/heartexlabs/label-studio-ml-backend:tesseract-master
mkdir -p data/tesseract

# Linux/WSL
podman run -d --name tesseract --network=host \
  -e LOG_LEVEL=DEBUG \
  -e LABEL_STUDIO_HOST=http://localhost:8080 \
  -v $(pwd)/data/tesseract:/data:Z \
  docker.io/heartexlabs/label-studio-ml-backend:tesseract-master

# macOS
podman run -d --name tesseract \
  -p 9090:9090 \
  -e LOG_LEVEL=DEBUG \
  -e LABEL_STUDIO_HOST=http://host.containers.internal:8080 \
  -v $(pwd)/data/tesseract:/data:Z \
  docker.io/heartexlabs/label-studio-ml-backend:tesseract-master
```

### 3. YOLO

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
cd ../../../..
```

### Running Manually

```bash
# Label Studio
source .venv/bin/activate
label-studio start --port 8080

# Tesseract
podman start tesseract

# YOLO
cd label-studio-ml-backend/label_studio_ml/examples/yolo
source .venv/bin/activate
LABEL_STUDIO_HOST=http://localhost:8080 PYTHONPATH=$(pwd) \
gunicorn --bind :9091 --workers 1 --threads 4 --timeout 0 _wsgi:app
```

### Stopping Manually

```bash
pkill -f "label-studio"
podman stop tesseract
pkill -f "gunicorn.*9091"
```

---

## Troubleshooting

**Label Studio slow to start:** First startup takes 1-2 minutes for database init.

**Check health:**
```bash
curl http://localhost:8080        # 302 = OK
curl http://localhost:9090/health # {"status":"UP"}
curl http://localhost:9091/health # {"status":"UP"}
```

**Podman issues:**
```bash
podman ps -a          # Check status
podman logs tesseract # View logs
podman rm tesseract   # Remove and recreate
```

**WSL networking:** If localhost doesn't work from Windows, get WSL IP:
```bash
hostname -I | awk '{print $1}'
```

---

## Repository Structure

```
labelstudio-local/
├── Makefile
├── README.md
├── scripts/
│   ├── setup.sh
│   ├── start.sh
│   ├── stop.sh
│   └── health.sh
├── label-studio-ml-backend/
│   └── label_studio_ml/examples/
│       ├── tesseract/
│       └── yolo/
│           └── models/
│               └── yolo11n.pt  ← included
└── data/  (created at runtime)
```
