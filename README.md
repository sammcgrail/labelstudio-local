# Label Studio Local Setup

Local Label Studio with Tesseract OCR, YOLO, EasyOCR, MobileSAM, and SAM2 ML backends. Includes example images and step-by-step usage guide.

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

### Core (make setup)

| Service | Port | Type | Platform |
|---------|------|------|----------|
| Label Studio | 8080 | Web UI | All |
| Tesseract OCR | 9090 | Container (Podman) | All |
| YOLO (v8/v11) | 9091 | Native Python | All |

### Extras (make extras, or install individually)

| Service | Port | Type | Platform | Install individually |
|---------|------|------|----------|---------------------|
| EasyOCR | 9092 | Container (Podman) | All | `make easyocr` |
| MobileSAM | 9093 | Native Python (CPU) | All | `make mobilesam` |
| SAM2 | 9094 | Native Python (GPU) | Linux/WSL (CUDA), macOS (MPS) | `make sam2` |

> SAM2 requires a GPU. On Linux/WSL it uses NVIDIA CUDA. On macOS it uses Apple Metal (MPS) — works on M1/M2/M3/M4 chips. Not available on CPU-only systems.

> **Included models:** `yolo11n.pt` (5.4MB) and `yolov8n.pt` (6.3MB) - ready to use.

## Commands

### Make (macOS/Linux)

```bash
make setup     # Install core (Label Studio, Tesseract, YOLO)
make start     # Start core services
make stop      # Stop all services
make health    # Check service status
make clean     # Remove installed components
make help      # Show all commands

# Extra ML backends
make extras        # Install all extras (EasyOCR, MobileSAM, SAM2)
make easyocr       # Install + start EasyOCR (port 9092)
make mobilesam     # Install + start MobileSAM (port 9093)
make sam2          # Install + start SAM2 (port 9094) [GPU]
make start-easyocr # Start EasyOCR (port 9092)
make start-sam     # Start MobileSAM (port 9093)
make start-sam2    # Start SAM2 (port 9094) [GPU]
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

### EasyOCR (extras)

Better multilingual OCR than Tesseract. Supports 80+ languages.

```xml
<View>
  <Image name="image" value="$image" zoom="true" zoomControl="true"/>
  <PolygonLabels name="label" toName="image" strokeWidth="2" smart="true">
    <Label value="Text" background="green"/>
  </PolygonLabels>
  <TextArea name="transcription" toName="image" editable="true"
            perRegion="true" required="false" maxSubmissions="1"
            rows="5" placeholder="Recognized Text"
            displayMode="region-list"/>
</View>
```

Configure languages via `LANG_LIST` env var (default: `en`). Set to `en,fr,de` etc.

### MobileSAM - Interactive Segmentation (extras)

Click or draw a rectangle to segment any object. No predefined classes needed.

```xml
<View>
  <Image name="image" value="$image" zoom="true" zoomControl="true"/>
  <BrushLabels name="label" toName="image">
    <Label value="Object" background="green"/>
  </BrushLabels>
  <KeyPointLabels name="kp" toName="image" smart="true">
    <Label value="Positive" background="green"/>
    <Label value="Negative" background="red"/>
  </KeyPointLabels>
</View>
```

> MobileSAM is interactive only - click keypoints or draw rectangles to guide segmentation. It does not auto-label in batch mode.

### SAM2 - Segment Anything 2 (extras, GPU required)

Meta's SAM2 for high-quality interactive segmentation. Requires GPU: NVIDIA CUDA on Linux/WSL, Apple MPS on macOS (M1/M2/M3/M4).

```xml
<View>
  <Image name="image" value="$image" zoom="true" zoomControl="true"/>
  <BrushLabels name="label" toName="image">
    <Label value="Object" background="green"/>
  </BrushLabels>
  <KeyPointLabels name="kp" toName="image" smart="true">
    <Label value="Positive" background="green"/>
    <Label value="Negative" background="red"/>
  </KeyPointLabels>
</View>
```

> SAM2 requires a GPU. It uses NVIDIA CUDA on Linux/WSL and Apple Metal (MPS) on macOS. Not available on CPU-only systems.

**YOLO Classes (80 COCO):** person, bicycle, car, motorcycle, airplane, bus, train, truck, boat, traffic light, fire hydrant, stop sign, parking meter, bench, bird, cat, dog, horse, sheep, cow, elephant, bear, zebra, giraffe, backpack, umbrella, handbag, tie, suitcase, frisbee, skis, snowboard, sports ball, kite, baseball bat, baseball glove, skateboard, surfboard, tennis racket, bottle, wine glass, cup, fork, knife, spoon, bowl, banana, apple, sandwich, orange, broccoli, carrot, hot dog, pizza, donut, cake, chair, couch, potted plant, bed, dining table, toilet, tv, laptop, mouse, remote, keyboard, cell phone, microwave, oven, toaster, sink, refrigerator, book, clock, vase, scissors, teddy bear, hair drier, toothbrush.

## How YOLO Model Selection Works

The YOLO backend uses the [ultralytics](https://github.com/ultralytics/ultralytics) library, which supports multiple YOLO versions through a unified API. You specify which model to use via the `model_path` attribute in your labeling config.

### Included Models

- `yolo11n.pt` - YOLO11 nano (5.4MB) - **included**
- `yolov8n.pt` - YOLOv8 nano (6.3MB) - **included**

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

## Usage Guide

This section walks through creating projects, importing images, connecting ML backends, and using auto-labeling and interactive annotation tools.

### First Launch

1. Run `make start` (or `./scripts/start.sh`)
2. Wait 1-2 minutes for Label Studio to initialize
3. Open **http://localhost:8080** in Chrome (recommended browser)
4. Create an account (first user becomes admin, data is local only)
5. You're now on the Projects page

### Example Images

The `examples/images/` folder contains test images for each ML backend:

| Image | Best For | What to Label |
|-------|----------|---------------|
| `street-scene.png` | YOLO | Cars, trucks, people, traffic light, stop sign |
| `animals-park.png` | YOLO | Dog, cat, horse, bird, person, bench |
| `shapes-objects.png` | YOLO | Apple, orange, bottle, cup, clock, keyboard, mouse, scissors, potted plant, vase, book |
| `document-scan.png` | Tesseract / EasyOCR | Invoice text, numbers, addresses |
| `text-sign.png` | Tesseract / EasyOCR | Sign text ("WELCOME TO CENTRAL PARK", hours, rules) |
| `aerial-view.png` | SAM2 / MobileSAM | Buildings, roads, cars (segmentation masks) |

### Step 1: Create a Project

1. Click **Create Project** (top right)
2. Enter a project name (e.g., "Object Detection Test")
3. Skip the Data Import tab for now (we'll import after configuring)
4. Go to the **Labeling Setup** tab

### Step 2: Configure the Labeling Interface

Click the **Code** button to switch to XML mode. Paste one of the labeling configurations from the [Labeling Configurations](#labeling-configurations) section above, depending on what you want to do:

- **YOLO object detection** — use the YOLO config with `<RectangleLabels>` and labels for `person`, `car`, `truck`, etc.
- **Tesseract OCR** — use the Tesseract config with `<RectangleLabels smart="true">` and `<TextArea>` for transcription
- **EasyOCR** — use the EasyOCR config with `<PolygonLabels smart="true">`
- **MobileSAM / SAM2 segmentation** — use the SAM config with `<BrushLabels>` and `<KeyPointLabels smart="true">`

Click **Save** after pasting.

> You can customize labels: add `<Label value="your_class"/>` tags for any classes you need. Use the `background` attribute to set colors (e.g., `background="#FF0000"`).

### Step 3: Import Images

1. Inside your project, click **Import** (top right of the Data Manager)
2. Click **Upload Files** and select images from `examples/images/`
3. Click **Import** to confirm

The images appear in the Data Manager as tasks, one per image.

> **Tip:** You can also drag and drop files, or import a folder. For production use with large datasets, use cloud storage (S3, GCS, Azure) with URL references.

### Step 4: Connect an ML Backend

1. Go to **Settings** (gear icon) > **Model**
2. Click **Connect Model**
3. Fill in:
   - **Name:** e.g., "YOLO" or "Tesseract"
   - **Backend URL:** the URL for your ML backend:

| Backend | URL |
|---------|-----|
| Tesseract OCR | `http://localhost:9090` |
| YOLO | `http://localhost:9091` |
| EasyOCR | `http://localhost:9092` |
| MobileSAM | `http://localhost:9093` |
| SAM2 | `http://localhost:9094` |

4. Check **Interactive preannotations** (this enables smart tools)
5. Click **Validate and Save**

If the connection succeeds, you'll see a green status. If it fails, run `make health` to check which backends are running.

> You can connect multiple ML backends to the same project. For example, connect both YOLO and SAM2 for detection + segmentation.

### Step 5: Auto-Label (Batch Predictions)

Auto-labeling generates predictions for all tasks at once using the connected ML backend.

**Method 1 — Automatic pre-labeling:**
1. Go to **Settings > Annotation**
2. Enable **"Use predictions to prelabel tasks"**
3. Under **Live Predictions**, select which model to use
4. Now when you open any task, predictions load automatically

**Method 2 — Retrieve predictions on demand:**
1. In the Data Manager, select tasks (checkbox on the left, or select all)
2. Click the **Actions** dropdown
3. Select **Retrieve Predictions**
4. Predictions are fetched from the ML backend and stored on each task

Predictions appear as **dashed outlines** in the labeling interface. They are read-only. To edit them, click a prediction to copy it into your annotation.

### Step 6: Interactive Annotation (Smart Tools)

Interactive annotation gives you real-time ML assistance as you label. This is the most powerful way to use the ML backends.

**Enable it:**
1. Make sure you checked **Interactive preannotations** when connecting the model (Step 4)
2. Open a task by clicking on it, or click **Label All Tasks** to enter label stream mode
3. In the labeling toolbar, toggle the **Auto-Annotation** switch (magic wand icon)

#### YOLO — Auto-Detect Objects

With YOLO connected and auto-annotation enabled:
1. Open an image (e.g., `street-scene.png`)
2. YOLO automatically detects objects and draws bounding boxes
3. Review the predictions — accept, modify, or delete as needed
4. Click **Submit** when done

YOLO detects all 80 COCO classes. Only labels that match your labeling config are shown. Add more `<Label>` tags to your config to see more detections.

#### Tesseract — Smart Rectangle OCR

With Tesseract connected and auto-annotation enabled:
1. Open a document image (e.g., `document-scan.png`)
2. Select the **Text** label
3. Draw a rectangle around any text region
4. Tesseract automatically reads the text and fills the transcription field
5. Review and correct the OCR text if needed
6. Repeat for each text block, then **Submit**

The `smart="true"` attribute on `<RectangleLabels>` enables this. Without it, you'd have to type text manually.

#### EasyOCR — Smart Polygon OCR

Similar to Tesseract but with polygon regions and better multilingual support:
1. Open a document or sign image
2. Select the **Text** label
3. Draw a polygon or rectangle around text
4. EasyOCR extracts the text automatically
5. Configure languages via the `LANG_LIST` env var (default: `en`)

#### MobileSAM / SAM2 — Click-to-Segment

This is the most interactive workflow. Click on any object to get a pixel-perfect segmentation mask.

1. Open an image (e.g., `aerial-view.png` or `shapes-objects.png`)
2. Select **Positive** under KeyPointLabels
3. Click on an object you want to segment
4. SAM generates a brush mask around the object
5. If the mask is too small, click another positive point on the missed area
6. If the mask includes unwanted area, switch to **Negative** and click on that area
7. The mask refines with each click
8. When satisfied, click **Submit**

**Tips for SAM segmentation:**
- **Positive clicks** tell SAM "include this area"
- **Negative clicks** tell SAM "exclude this area"
- Start with one click in the center of the object
- Add more clicks to refine edges
- You can also draw a rectangle around the object for a rough initial mask
- SAM2 produces higher quality masks than MobileSAM but requires a GPU
- Works best on distinct objects with clear boundaries

### Step 7: Manual Annotation Tools

You can always annotate manually, with or without ML backends.

#### Drawing Bounding Boxes
1. Select the rectangle tool and a label
2. Click and drag to draw a box, or click two opposite corners
3. Resize by dragging corner handles
4. Move by dragging the center
5. To draw overlapping boxes: hold **Ctrl** (or **Cmd** on Mac) while clicking, or press the rectangle hotkey again

#### Drawing Polygons
1. Select the polygon tool and a label
2. Click to place vertices
3. Double-click to close the polygon
4. Vertices can be adjusted after closing

#### Brush Painting
1. Select the brush tool and a label
2. Paint over the region
3. Use the eraser to remove parts (select the region first in the sidebar, then erase)
4. Adjust brush size with the slider

### Step 8: Review and Submit

- **Submit** saves the annotation and advances to the next task
- **Update** saves changes to an existing annotation
- **Skip** moves to the next task without annotating
- Use the **Outliner panel** (left sidebar) to see all regions, edit coordinates precisely, change labels, or delete regions
- **Keyboard shortcuts:** Press **Ctrl+Enter** to submit, **Backspace** to delete selected region

### Workflow Summary

```
┌─────────────┐    ┌──────────────┐    ┌──────────────────┐
│ Create       │    │ Import       │    │ Connect ML       │
│ Project      │───>│ Images       │───>│ Backend          │
└─────────────┘    └──────────────┘    └──────────────────┘
                                              │
                         ┌────────────────────┼────────────────────┐
                         │                    │                    │
                         v                    v                    v
                   ┌───────────┐     ┌──────────────┐    ┌──────────────┐
                   │ Auto-Label│     │ Interactive  │    │ Manual       │
                   │ (batch)   │     │ (smart tools)│    │ Annotation   │
                   └───────────┘     └──────────────┘    └──────────────┘
                         │                    │                    │
                         └────────────────────┼────────────────────┘
                                              v
                                     ┌──────────────┐
                                     │ Review &     │
                                     │ Submit       │
                                     └──────────────┘
                                              │
                                              v
                                     ┌──────────────┐
                                     │ Export       │
                                     │ Annotations  │
                                     └──────────────┘
```

### Exporting Annotations

1. In the Data Manager, select tasks (or select all)
2. Click **Export**
3. Choose a format:
   - **JSON** — Label Studio native format (recommended)
   - **COCO** — standard for object detection
   - **VOC** — Pascal VOC XML format
   - **YOLO** — YOLO txt format
4. Download the export file

### Project Recipes

Quick-start configurations for common workflows.

#### Recipe: Document OCR Pipeline

Set up a project to extract text from scanned documents.

1. Create project named "Document OCR"
2. Use the [Tesseract labeling config](#tesseract-ocr)
3. Import images from `examples/images/` (document-scan.png, text-sign.png)
4. Connect Tesseract at `http://localhost:9090` with interactive preannotations
5. Open a task, enable Auto-Annotation, draw rectangles around text blocks
6. Tesseract fills in the transcription automatically

#### Recipe: Street Object Detection

Detect cars, people, and objects in street images.

1. Create project named "Street Detection"
2. Use the [YOLO labeling config](#yolo-object-detection-v8v11) — add all labels you want to detect
3. Import `street-scene.png` and `animals-park.png`
4. Connect YOLO at `http://localhost:9091` with interactive preannotations
5. Open a task — YOLO auto-detects objects
6. Review bounding boxes, adjust labels, submit

#### Recipe: Image Segmentation with SAM2

Segment objects with pixel-perfect masks.

1. Create project named "Image Segmentation"
2. Use the [SAM2 labeling config](#sam2---segment-anything-2-extras-gpu-required) — add labels for your object classes
3. Import `aerial-view.png` and `shapes-objects.png`
4. Connect SAM2 at `http://localhost:9094` with interactive preannotations
5. Open a task, enable Auto-Annotation, select Positive keypoint label
6. Click on objects — SAM2 generates segmentation masks
7. Use Negative clicks to exclude unwanted areas, submit when done

#### Recipe: Full Pipeline (YOLO + SAM2)

Use YOLO to find objects, then SAM2 to segment them precisely.

1. Create project with both bounding box and segmentation labels:
```xml
<View>
  <Image name="image" value="$image" zoom="true" zoomControl="true"/>
  <RectangleLabels name="bbox" toName="image">
    <Label value="person" background="red"/>
    <Label value="car" background="blue"/>
    <Label value="truck" background="green"/>
  </RectangleLabels>
  <BrushLabels name="segment" toName="image">
    <Label value="person" background="red"/>
    <Label value="car" background="blue"/>
  </BrushLabels>
  <KeyPointLabels name="kp" toName="image" smart="true">
    <Label value="Positive" background="green"/>
    <Label value="Negative" background="red"/>
  </KeyPointLabels>
</View>
```
2. Connect both YOLO (`http://localhost:9091`) and SAM2 (`http://localhost:9094`)
3. YOLO provides bounding box predictions, SAM2 provides segmentation on click
4. Review detections, click objects for precise masks, submit

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

**Label Studio slow to start:** Label Studio takes 1-2 minutes to start up. It initializes the database, checks PyPI for updates, and runs migrations. Wait until you see `Starting development server at http://0.0.0.0:8080/` in the console before opening the browser. The ML backends (Tesseract and YOLO) start much faster.

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
├── examples/
│   └── images/
│       ├── street-scene.png     ← YOLO test (cars, people, traffic)
│       ├── animals-park.png     ← YOLO test (dog, cat, horse, bird)
│       ├── shapes-objects.png   ← YOLO test (bottle, cup, apple, clock)
│       ├── document-scan.png    ← OCR test (invoice with text)
│       ├── text-sign.png        ← OCR test (sign with text)
│       └── aerial-view.png      ← SAM test (buildings, roads)
├── scripts/
│   ├── setup.sh
│   ├── start.sh
│   ├── stop.sh
│   └── health.sh
├── label-studio-ml-backend/   (cloned at setup)
│   └── label_studio_ml/examples/
│       ├── tesseract/
│       └── yolo/
│           └── models/
│               ├── yolo11n.pt   ← included
│               └── yolov8n.pt   ← included
└── data/  (created at runtime)
```
