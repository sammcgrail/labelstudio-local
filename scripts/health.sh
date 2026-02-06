#!/bin/bash

echo "=== Service Health Check ==="

echo -n "Label Studio (8080): "
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8080 2>/dev/null)
if [ "$HTTP_CODE" = "302" ] || [ "$HTTP_CODE" = "200" ]; then
    echo "OK (HTTP $HTTP_CODE)"
else
    echo "DOWN"
fi

echo -n "Tesseract (9090):    "
HEALTH=$(curl -s http://localhost:9090/health 2>/dev/null)
if echo "$HEALTH" | grep -q '"status":"UP"'; then
    echo "OK"
else
    echo "DOWN"
fi

echo -n "YOLOv8 (9091):       "
HEALTH=$(curl -s http://localhost:9091/health 2>/dev/null)
if echo "$HEALTH" | grep -q '"status":"UP"'; then
    echo "OK"
else
    echo "DOWN"
fi

echo -n "EasyOCR (9092):      "
HEALTH=$(curl -s http://localhost:9092/health 2>/dev/null)
if echo "$HEALTH" | grep -q '"status":"UP"'; then
    echo "OK"
else
    echo "DOWN"
fi

echo -n "MobileSAM (9093):    "
HEALTH=$(curl -s http://localhost:9093/health 2>/dev/null)
if echo "$HEALTH" | grep -q '"status":"UP"'; then
    echo "OK"
else
    echo "DOWN"
fi

echo -n "SAM2 (9094):         "
HEALTH=$(curl -s http://localhost:9094/health 2>/dev/null)
if echo "$HEALTH" | grep -q '"status":"UP"'; then
    echo "OK"
else
    echo "DOWN"
fi
