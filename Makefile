SHELL := /bin/bash
.PHONY: setup setup-labelstudio setup-tesseract setup-yolo start stop health clean extras setup-easyocr setup-sam setup-sam2 start-easyocr start-sam start-sam2

# Detect OS
UNAME_S := $(shell uname -s)
ROOT_DIR := $(shell pwd)
EXAMPLES_DIR := $(ROOT_DIR)/label-studio-ml-backend/label_studio_ml/examples
YOLO_DIR := $(EXAMPLES_DIR)/yolo
EASYOCR_DIR := $(EXAMPLES_DIR)/easyocr
SAM_DIR := $(EXAMPLES_DIR)/segment_anything_model
SAM2_DIR := $(EXAMPLES_DIR)/segment_anything_2_image
SAM2_REPO := $(ROOT_DIR)/sam2

# Default target
all: setup

#
# Setup targets
#

setup: setup-labelstudio setup-ml-backend setup-tesseract setup-yolo
	@echo ""
	@echo "=== Setup Complete ==="
	@echo "Run 'make start' to start all services"

setup-labelstudio:
	@echo "=== Setting up Label Studio ==="
	uv venv .venv
	. .venv/bin/activate && uv pip install label-studio

setup-ml-backend:
	@echo "=== Cloning ML Backend Repository ==="
	@if [ ! -d "label-studio-ml-backend" ]; then \
		git clone https://github.com/HumanSignal/label-studio-ml-backend.git; \
	else \
		echo "ML backend repo already exists"; \
	fi

setup-tesseract:
	@echo "=== Setting up Tesseract OCR Backend ==="
	mkdir -p data/tesseract
	podman pull docker.io/heartexlabs/label-studio-ml-backend:tesseract-master
	-podman rm -f tesseract 2>/dev/null
ifeq ($(UNAME_S),Darwin)
	podman run -d \
		--name tesseract \
		-p 9090:9090 \
		-e LOG_LEVEL=DEBUG \
		-e LABEL_STUDIO_HOST=http://host.containers.internal:8080 \
		-v $(ROOT_DIR)/data/tesseract:/data:Z \
		docker.io/heartexlabs/label-studio-ml-backend:tesseract-master
else
	podman run -d \
		--name tesseract \
		--network=host \
		-e LOG_LEVEL=DEBUG \
		-e LABEL_STUDIO_HOST=http://localhost:8080 \
		-v $(ROOT_DIR)/data/tesseract:/data:Z \
		docker.io/heartexlabs/label-studio-ml-backend:tesseract-master
endif
	-podman stop tesseract

setup-yolo:
	@echo "=== Setting up YOLOv8 Backend ==="
	cd $(YOLO_DIR) && uv venv .venv
	cd $(YOLO_DIR) && . .venv/bin/activate && uv pip install \
		gunicorn \
		ultralytics \
		tqdm \
		"torchmetrics<1.8.0" \
		"label-studio-ml @ git+https://github.com/HumanSignal/label-studio-ml-backend.git@master" \
		"label-studio-sdk @ git+https://github.com/HumanSignal/label-studio-sdk.git"
	mkdir -p $(YOLO_DIR)/data/server $(YOLO_DIR)/models $(YOLO_DIR)/cache_dir

#
# Run targets
#

start: start-tesseract start-yolo start-labelstudio

start-labelstudio:
	@echo "Starting Label Studio (port 8080)..."
	@echo ""
	@echo "NOTE: Label Studio takes 1-2 minutes to start on first load."
	@echo "      Wait until you see 'Starting development server' before opening the browser."
	@echo ""
	@echo "  Label Studio: http://localhost:8080"
	@echo "  Tesseract:    http://localhost:9090"
	@echo "  YOLO:         http://localhost:9091"
	@echo ""
	@echo "  Extras (if installed via 'make extras'):"
	@echo "  EasyOCR:      http://localhost:9092  (make start-easyocr)"
	@echo "  MobileSAM:    http://localhost:9093  (make start-sam)"
	@echo "  SAM2:         http://localhost:9094  (make start-sam2) [GPU]"
	@echo ""
	. .venv/bin/activate && label-studio start --port 8080

start-tesseract:
	@echo "Starting Tesseract OCR (port 9090)..."
	-podman start tesseract

start-yolo:
	@echo "Starting YOLOv8 (port 9091)..."
	cd $(YOLO_DIR) && . .venv/bin/activate && \
		LABEL_STUDIO_HOST=http://localhost:8080 \
		PYTHONPATH=$(YOLO_DIR) \
		gunicorn --bind :9091 --workers 1 --threads 4 --timeout 0 _wsgi:app &

stop:
	@echo "=== Stopping all services ==="
	-pkill -f "label-studio" 2>/dev/null || true
	-podman stop tesseract 2>/dev/null || true
	-podman stop easyocr 2>/dev/null || true
	-pkill -f "gunicorn.*9091" 2>/dev/null || true
	-pkill -f "gunicorn.*9093" 2>/dev/null || true
	-pkill -f "gunicorn.*9094" 2>/dev/null || true
	@echo "All services stopped."

#
# Extras - additional ML backends (EasyOCR, MobileSAM)
#

extras: setup-ml-backend setup-easyocr setup-sam setup-sam2
	@echo ""
	@echo "=== Extras Setup Complete ==="
	@echo "  EasyOCR:   make start-easyocr  (port 9092)"
	@echo "  MobileSAM: make start-sam      (port 9093)"
	@echo "  SAM2:      make start-sam2     (port 9094) [GPU required]"

setup-easyocr:
	@echo "=== Setting up EasyOCR Backend ==="
	mkdir -p data/easyocr
	podman pull docker.io/heartexlabs/label-studio-ml-backend:easyocr-master
	-podman rm -f easyocr 2>/dev/null
ifeq ($(UNAME_S),Darwin)
	podman run -d \
		--name easyocr \
		-p 9092:9090 \
		-e LOG_LEVEL=DEBUG \
		-e DEVICE=cpu \
		-e LANG_LIST=en \
		-e LABEL_STUDIO_HOST=http://host.containers.internal:8080 \
		-v $(ROOT_DIR)/data/easyocr:/data:Z \
		docker.io/heartexlabs/label-studio-ml-backend:easyocr-master
else
	podman run -d \
		--name easyocr \
		-p 9092:9090 \
		-e LOG_LEVEL=DEBUG \
		-e DEVICE=cpu \
		-e LANG_LIST=en \
		-e LABEL_STUDIO_HOST=http://localhost:8080 \
		-v $(ROOT_DIR)/data/easyocr:/data:Z \
		docker.io/heartexlabs/label-studio-ml-backend:easyocr-master
endif
	-podman stop easyocr

setup-sam:
	@echo "=== Setting up MobileSAM Backend ==="
	cd $(SAM_DIR) && uv venv .venv
	cd $(SAM_DIR) && . .venv/bin/activate && uv pip install \
		"numpy>=2,<2.3.0" \
		label_studio_converter \
		"opencv-python-headless>=4.12.0,<5.0.0" \
		"onnxruntime>=1.18.0" \
		"onnx>=1.15.0" \
		"torch==2.0.1" \
		"torchvision==0.15.2" \
		"gunicorn==22.0.0" \
		"timm==0.4.12" \
		"segment_anything @ git+https://github.com/facebookresearch/segment-anything.git" \
		"mobile-sam @ git+https://github.com/ChaoningZhang/MobileSAM.git" \
		"label-studio-ml @ git+https://github.com/heartexlabs/label-studio-ml-backend.git"
	mkdir -p $(SAM_DIR)/data

start-easyocr:
	@echo "Starting EasyOCR (port 9092)..."
	-podman start easyocr

start-sam:
	@echo "Starting MobileSAM (port 9093)..."
	cd $(SAM_DIR) && . .venv/bin/activate && \
		SAM_CHOICE=MobileSAM \
		LABEL_STUDIO_HOST=http://localhost:8080 \
		PYTHONPATH=$(SAM_DIR) \
		gunicorn --bind :9093 --workers 1 --threads 4 --timeout 0 _wsgi:app &

setup-sam2:
	@echo "=== Setting up SAM2 Backend (requires GPU: NVIDIA CUDA or Apple MPS) ==="
	@if [ ! -d "$(SAM2_REPO)" ]; then \
		git clone --depth 1 --branch main --single-branch https://github.com/facebookresearch/sam2.git $(SAM2_REPO); \
	else \
		echo "sam2 repo already exists"; \
	fi
	cd $(SAM2_REPO) && uv venv .venv
	cd $(SAM2_REPO) && . .venv/bin/activate && uv pip install \
		-e . \
		gunicorn \
		"label-studio-ml @ git+https://github.com/HumanSignal/label-studio-ml-backend.git@master" \
		"label-studio-sdk @ git+https://github.com/HumanSignal/label-studio-sdk.git"
	@echo "Downloading SAM2 checkpoints..."
	cd $(SAM2_REPO)/checkpoints && bash download_ckpts.sh
	mkdir -p $(SAM2_DIR)/data

start-sam2:
	@echo "Starting SAM2 (port 9094, GPU)..."
ifeq ($(UNAME_S),Darwin)
	cd $(SAM2_REPO) && . .venv/bin/activate && \
		DEVICE=mps \
		MODEL_CONFIG=configs/sam2.1/sam2.1_hiera_l.yaml \
		MODEL_CHECKPOINT=sam2.1_hiera_large.pt \
		LABEL_STUDIO_HOST=http://localhost:8080 \
		PYTHONPATH=$(SAM2_DIR) \
		gunicorn --bind :9094 --workers 1 --threads 4 --timeout 0 \
			--pythonpath $(SAM2_DIR) _wsgi:app &
else
	cd $(SAM2_REPO) && . .venv/bin/activate && \
		DEVICE=cuda \
		MODEL_CONFIG=configs/sam2.1/sam2.1_hiera_l.yaml \
		MODEL_CHECKPOINT=sam2.1_hiera_large.pt \
		LABEL_STUDIO_HOST=http://localhost:8080 \
		PYTHONPATH=$(SAM2_DIR) \
		gunicorn --bind :9094 --workers 1 --threads 4 --timeout 0 \
			--pythonpath $(SAM2_DIR) _wsgi:app &
endif

#
# Utility targets
#

health:
	@echo "=== Service Health Check ==="
	@echo -n "Label Studio (8080): "; \
	HTTP=$$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8080 2>/dev/null); \
	if [ "$$HTTP" = "302" ] || [ "$$HTTP" = "200" ]; then echo "OK"; else echo "DOWN"; fi
	@echo -n "Tesseract (9090): "; \
	if curl -s http://localhost:9090/health 2>/dev/null | grep -q '"status":"UP"'; then echo "OK"; else echo "DOWN"; fi
	@echo -n "YOLOv8 (9091): "; \
	if curl -s http://localhost:9091/health 2>/dev/null | grep -q '"status":"UP"'; then echo "OK"; else echo "DOWN"; fi
	@echo -n "EasyOCR (9092): "; \
	if curl -s http://localhost:9092/health 2>/dev/null | grep -q '"status":"UP"'; then echo "OK"; else echo "DOWN"; fi
	@echo -n "MobileSAM (9093): "; \
	if curl -s http://localhost:9093/health 2>/dev/null | grep -q '"status":"UP"'; then echo "OK"; else echo "DOWN"; fi
	@echo -n "SAM2 (9094): "; \
	if curl -s http://localhost:9094/health 2>/dev/null | grep -q '"status":"UP"'; then echo "OK"; else echo "DOWN"; fi

clean:
	@echo "=== Cleaning up ==="
	-podman rm -f tesseract 2>/dev/null
	-podman rm -f easyocr 2>/dev/null
	rm -rf .venv
	rm -rf data
	rm -rf $(YOLO_DIR)/.venv
	rm -rf $(YOLO_DIR)/models/*.pt
	rm -rf $(SAM_DIR)/.venv
	rm -rf $(SAM2_REPO)
	@echo "Cleaned."

help:
	@echo "Label Studio Local Setup"
	@echo ""
	@echo "Usage:"
	@echo "  make setup     - Install everything (Label Studio, Tesseract, YOLO)"
	@echo "  make start     - Start all services"
	@echo "  make stop      - Stop all services"
	@echo "  make health    - Check service status"
	@echo "  make clean     - Remove all installed components"
	@echo ""
	@echo "Individual setup:"
	@echo "  make setup-labelstudio  - Install Label Studio only"
	@echo "  make setup-tesseract    - Setup Tesseract container only"
	@echo "  make setup-yolo         - Setup YOLO backend only"
	@echo ""
	@echo "Individual start:"
	@echo "  make start-labelstudio  - Start Label Studio only"
	@echo "  make start-tesseract    - Start Tesseract only"
	@echo "  make start-yolo         - Start YOLO only"
	@echo ""
	@echo "Extras (install individually or all at once):"
	@echo "  make extras             - Install all extras (EasyOCR, MobileSAM, SAM2)"
	@echo "  make easyocr            - Install + start EasyOCR (port 9092)"
	@echo "  make mobilesam          - Install + start MobileSAM (port 9093)"
	@echo "  make sam2               - Install + start SAM2 (port 9094) [GPU required]"
	@echo ""
	@echo "Start extras individually:"
	@echo "  make start-easyocr      - Start EasyOCR (port 9092)"
	@echo "  make start-sam          - Start MobileSAM (port 9093)"
	@echo "  make start-sam2         - Start SAM2 (port 9094) [GPU required]"

#
# Shorthand aliases: make easyocr, make mobilesam, make sam2
#

easyocr: setup-ml-backend setup-easyocr start-easyocr
mobilesam: setup-ml-backend setup-sam start-sam
sam2: setup-ml-backend setup-sam2 start-sam2
