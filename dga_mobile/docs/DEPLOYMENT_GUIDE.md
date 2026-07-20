# Deployment Guide

This guide details hosting, network parameters, and scaling requirements.

## 1. Server Sizing
- **Minimum RAM**: 1 GB.
- **Recommended RAM**: 2 GB (provides buffer space for loading all PyTorch model weights).
- **GPU Optimization**: If CUDA-supporting GPUs are present, `torch` automatically utilizes GPU execution, cutting latency to <50ms.

## 2. Running behind Reverse Proxy
We recommend running Uvicorn behind Nginx:
```nginx
server {
    listen 80;
    server_name api.durian-guardian.com;

    location / {
        proxy_pass http://127.0.0.1:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
```
