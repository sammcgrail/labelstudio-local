# Example Images

Test images for Label Studio ML backend evaluation.

## Images

| File | Size | Purpose | ML Backend |
|------|------|---------|------------|
| `street-scene.png` | 800x600 | Cars, trucks, people, traffic light, stop sign | YOLO |
| `animals-park.png` | 800x600 | Dog, cat, horse, bird, person, bench | YOLO |
| `shapes-objects.png` | 800x600 | Apple, orange, bottle, cup, keyboard, mouse, clock, scissors, potted plant, vase, book | YOLO |
| `document-scan.png` | 600x800 | Invoice with text, numbers, addresses, table | Tesseract / EasyOCR |
| `text-sign.png` | 600x400 | Park sign with text at various sizes | Tesseract / EasyOCR |
| `aerial-view.png` | 800x600 | Overhead view with buildings, roads, cars | MobileSAM / SAM2 |

## How to Use

1. Start Label Studio with `make start`
2. Create a project and configure a labeling interface
3. Click **Import** in the Data Manager
4. Upload images from this folder
5. Connect an ML backend and start labeling

See the main [README](../README.md#usage-guide) for detailed step-by-step instructions.
