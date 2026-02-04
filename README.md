# Label Studio Local Setup

Local Label Studio installation with Tesseract OCR and YOLOv8 ML backends.

## Requirements

- Python 3.12+
- [uv](https://docs.astral.sh/uv/getting-started/installation/) - `curl -LsSf https://astral.sh/uv/install.sh | sh`
- [Podman](https://podman.io/docs/installation) - container runtime
- make

## Quick Start

```bash
git clone https://github.com/sammcgrail/labelstudio-local.git
cd labelstudio-local
make setup
make start
```

## Commands

```bash
make setup     # Install everything (Label Studio, Tesseract, YOLO)
make start     # Start all services
make stop      # Stop all services
make health    # Check service status
make clean     # Remove all installed components
make help      # Show all available commands
```

## Services

| Service | Port | URL |
|---------|------|-----|
| Label Studio | 8080 | http://localhost:8080 |
| Tesseract OCR | 9090 | http://localhost:9090 |
| YOLOv8 | 9091 | http://localhost:9091 |

## Repository Structure

```
labelstudio-local/
├── Makefile                    # Build/run commands
├── README.md                   # This file
├── SETUP.md                    # Detailed setup notes
├── label-studio-ml-backend/    # ML backend code (included)
│   └── label_studio_ml/
│       └── examples/
│           ├── tesseract/      # Tesseract OCR backend
│           └── yolo/           # YOLOv8 backend
└── data/                       # Runtime data (gitignored)
```

## Connecting ML Backends in Label Studio

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

### Check service health

```bash
make health
```

### Podman issues

```bash
podman ps -a          # Check container status
podman logs tesseract # View logs
```

See [SETUP.md](SETUP.md) for detailed manual setup instructions.
