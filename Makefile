.PHONY: setup setup-labelstudio setup-tesseract setup-yolo start stop health clean

# Detect OS
UNAME_S := $(shell uname -s)
ROOT_DIR := $(shell pwd)
YOLO_DIR := $(ROOT_DIR)/label-studio-ml-backend/label_studio_ml/examples/yolo

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

setup-tesseract: setup-ml-backend
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

setup-yolo: setup-ml-backend
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
	-pkill -f "gunicorn.*9091" 2>/dev/null || true
	@echo "All services stopped."

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

clean:
	@echo "=== Cleaning up ==="
	-podman rm -f tesseract 2>/dev/null
	rm -rf .venv
	rm -rf label-studio-ml-backend
	rm -rf data
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
