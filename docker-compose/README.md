# Laya CUDA Docker Compose

This directory contains the Docker Compose deployment configuration and documentation for running the CUDA-accelerated Laya decision engine using the image **`vinaybalamuru/laya:cuda`**.

---

## Architecture & Services

The configuration provides two services using NVIDIA GPU device reservations:

1. **`laya-serve`** (HTTP REST Server):
   - A long-running daemon (FastAPI / Uvicorn) serving Jev / System One compatible inference over HTTP.
   - Default port: `8000` (mapped to host `0.0.0.0:8000`).
   - Supports optional Bearer token authentication via `LAYA_API_KEY`.
   - Includes automatic restart policy and health check integration.

2. **`laya`** (One-shot CLI):
   - Runs a sample one-off prediction request or custom batch command using GPU acceleration, prints JSON results, and exits.

3. **`laya_model-cache`** (Persistent Volume):
   - Named volume mapped to `/home/laya/.cache/huggingface`.
   - Checkpoints downloaded on initial launch persist across container restarts and rebuilds.

---

## Quickstart

Run commands from the repository root:

```bash
# 1. Start the HTTP server in background
docker compose -f docker-compose/docker-compose.yml up -d laya-serve

# 2. Check server health
curl -s http://localhost:8000/health

# 3. View live server logs
docker compose -f docker-compose/docker-compose.yml logs -f laya-serve

# 4. Stop the server
docker compose -f docker-compose/docker-compose.yml down

# 5. Run a one-shot CLI quickstart test
docker compose -f docker-compose/docker-compose.yml run --rm laya
```

> **Tip:** You can also use [`manage.sh`](../manage.sh) in the root directory for an interactive menu that wraps these commands.

---

## Configuration (`.env`)

Copy `env.example` to create your `.env` file:

```bash
cp docker-compose/env.example docker-compose/.env
```

| Variable | Default | Description |
|---|---|---|
| `LAYA_PORT` | `8000` | Host port to publish the HTTP API on. |
| `LAYA_BIND_ADDRESS` | `0.0.0.0` | Host IP binding (`0.0.0.0` for all interfaces/LAN; `127.0.0.1` for localhost only). |
| `LAYA_API_KEY` | *(empty)* | Optional secret key. When set, requests must pass `Authorization: Bearer <key>`. |
| `HF_TOKEN` | *(empty)* | Optional Hugging Face token (avoids rate limits during downloads). |
| `LAYA_PRELOAD` | `1` | `1` preloads models into GPU VRAM on container startup; `0` lazy loads on first request. |
| `LAYA_GPU_ID` | `0` | Host GPU device index to pass to the container. |
| `LAYA_DEVICE` | `cuda` | Target compute device (`cuda` or `cpu`). |
| `LAYA_CUDA_AMP` | *(empty)* | CUDA autocast precision: `fp16`, `bf16`, or empty for checkpoint default. |
| `LAYA_CACHE_VOLUME` | `laya_model-cache` | Docker volume name storing Hugging Face weights. |

---

## API Endpoints

### 1. Healthcheck: `GET /health`

Returns container status, compute device, and loaded checkpoints. Does not require authentication.

```bash
curl -s http://localhost:8000/health
```

Example response:
```json
{
  "status": "ok",
  "device": "cuda:0",
  "checkpoint_devices": {
    "multilingual": "cuda:0"
  }
}
```

### 2. Decision Inference: `POST /v1/systemone`

Accepts an application `state` (context/observation) and a list of `questions` (candidate decisions or hypotheses), returning probability scores for each.

#### Unauthenticated (when `LAYA_API_KEY` is not set):
```bash
curl -X POST http://localhost:8000/v1/systemone \
  -H "Content-Type: application/json" \
  -d '{
    "state": "Customer wants to upgrade their existing subscription plan.",
    "questions": [
      "Is this a sales inquiry?",
      "Is this a technical bug report?",
      "Is this a billing cancellation?"
    ]
  }'
```

#### Authenticated (when `LAYA_API_KEY=my-secret-key-12345` is set):
```bash
curl -X POST http://localhost:8000/v1/systemone \
  -H "Authorization: Bearer my-secret-key-12345" \
  -H "Content-Type: application/json" \
  -d '{
    "state": "Customer wants to upgrade their existing subscription plan.",
    "questions": [
      "Is this a sales inquiry?",
      "Is this a technical bug report?"
    ]
  }'
```

Example response:
```json
{
  "choice": "Is this a sales inquiry?",
  "score": 0.9421,
  "confidence": 0.8842,
  "scores": [0.9421, 0.0579],
  "model": "english"
}
```

---

## Python Client Example

```python
import requests

url = "http://localhost:8000/v1/systemone"
headers = {
    # Include if LAYA_API_KEY is configured:
    # "Authorization": "Bearer my-secret-key-12345",
    "Content-Type": "application/json",
}
payload = {
    "state": "The user reported an error 500 when saving preferences.",
    "questions": [
        "Is this a backend error?",
        "Is this a feature request?",
    ],
}

response = requests.post(url, json=payload, headers=headers)
print(response.json())
```

---

## Troubleshooting

- **Check GPU access inside container:**
  ```bash
  docker run --rm --gpus all vinaybalamuru/laya:cuda python -c \
    'import torch; assert torch.cuda.is_available(); print("Device:", torch.cuda.get_device_name(0))'
  ```
- **Inspect container logs:**
  ```bash
  docker compose -f docker-compose/docker-compose.yml logs -f laya-serve
  ```
- **Reset downloaded model weights cache:**
  ```bash
  docker compose -f docker-compose/docker-compose.yml down --volumes
  ```
