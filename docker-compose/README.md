# Laya Docker Compose Deployment (CUDA & CPU)

This directory contains Docker Compose deployment configurations and documentation for running the Laya decision engine using pre-built images from Docker Hub:
- **`vinaybalamuru/laya:cuda`** (NVIDIA GPU accelerated via PyTorch CUDA 13.0)
- **`vinaybalamuru/laya:cpu`** (Lightweight pure CPU build, ~371 MB compressed)

For official Laya Docker documentation, see [nandhakishorm.github.io/laya/docker/](https://nandhakishorm.github.io/laya/docker/).

---

## Stacks & Architectures

| Stack | File | Default Port | Device | Use Case |
|---|---|---|---|---|
| **CUDA (GPU)** | `docker-compose.yml` | `8000` (or `8111`) | NVIDIA GPU | Ultra-low latency (<15ms P50), production inference |
| **CPU Only** | `docker-compose.cpu.yml` | `8112` | Host CPU (OMP) | Lightweight VPS, dev laptops, hardware without NVIDIA GPUs |

Both stacks share the named volume **`laya_model-cache`**, meaning downloaded weights are cached on the host and instantly shared between CPU and CUDA services without re-downloading.

---

## Quickstart

Run commands from the repository root:

### 1. Launch CUDA Stack (GPU)
```bash
# Start CUDA HTTP server in the background
docker compose --env-file docker-compose/.env -f docker-compose/docker-compose.yml up -d laya-serve

# Check health
curl -s http://localhost:8111/health

# Run a sample CLI request on GPU
docker compose --env-file docker-compose/.env -f docker-compose/docker-compose.yml run --rm laya
```

### 2. Launch CPU Stack (No GPU needed)
```bash
# Start CPU HTTP server in the background
docker compose --env-file docker-compose/.env -f docker-compose/docker-compose.cpu.yml up -d laya-serve

# Check health
curl -s http://localhost:8112/health

# Run a sample CLI request on CPU
docker compose --env-file docker-compose/.env -f docker-compose/docker-compose.cpu.yml run --rm laya
```

> **Tip:** You can also run `./manage.sh` in the repository root for an interactive menu managing both stacks.

---

## Configuration (`.env`)

Copy `env.example` to create your `.env` file:

```bash
cp docker-compose/env.example docker-compose/.env
```

| Variable | Default | Stack | Description |
|---|---|---|---|
| `LAYA_IMAGE` | `vinaybalamuru/laya:cuda` | CUDA | CUDA Docker image tag |
| `LAYA_CPU_IMAGE` | `vinaybalamuru/laya:cpu` | CPU | CPU Docker image tag |
| `LAYA_PORT` | `8000` | CUDA | Published host port for CUDA server |
| `LAYA_CPU_PORT` | `8112` | CPU | Published host port for CPU server |
| `LAYA_BIND_ADDRESS` | `0.0.0.0` | Both | Bind address (`0.0.0.0` for LAN; `127.0.0.1` for local only) |
| `LAYA_API_KEY` | *(empty)* | Both | Optional secret key for Bearer authentication |
| `HF_TOKEN` | *(empty)* | Both | Optional Hugging Face token (avoids download rate limits) |
| `LAYA_CACHE_VOLUME` | `laya_model-cache` | Both | Shared volume name for downloaded model checkpoints |
| `LAYA_MAX_LOADED` | `1` | Both | Max models kept resident in memory/VRAM (1 avoids OOM) |
| `LAYA_MODELS` | `english` | Both | Specific model to preload (`english`, `multilingual`, or empty) |
| `LAYA_PRELOAD` | `1` | Both | `1` preloads checkpoint on startup, `0` lazy loads |
| `LAYA_GPU_ID` | `0` | CUDA | NVIDIA GPU device index to reserve |
| `LAYA_CUDA_AMP` | `fp16` | CUDA | CUDA autocast precision (`fp16` or `bf16`) |
| `LAYA_CPU_THREADS` | `4` | CPU | Number of OpenMP CPU inference threads |
| `LAYA_CPU_AMP` | *(empty)* | CPU | Optional CPU autocast (`bf16` or empty for `fp32`) |

---

## API Inference (`POST /v1/systemone`)

Example query:

```bash
# To CUDA Server (port 8111):
curl -s -X POST http://localhost:8111/v1/systemone \
  -H "Authorization: Bearer my-secret-laya-api-key" \
  -H "Content-Type: application/json" \
  -d '{
    "state": "The user encountered an error 500 when saving account settings.",
    "questions": {
      "category": {
        "type": "choice",
        "instructions": "Classify the problem",
        "criteria": {
          "server_error": "500, crash, unhandled exception",
          "user_error": "invalid form input, bad password",
          "feature_request": "new functionality desired"
        }
      }
    }
  }' | jq .

# To CPU Server (port 8112):
curl -s -X POST http://localhost:8112/v1/systemone \
  -H "Authorization: Bearer my-secret-laya-api-key" \
  -H "Content-Type: application/json" \
  -d '{
    "state": "The user encountered an error 500 when saving account settings.",
    "questions": {
      "category": {
        "type": "choice",
        "instructions": "Classify the problem",
        "criteria": {
          "server_error": "500, crash, unhandled exception",
          "user_error": "invalid form input, bad password",
          "feature_request": "new functionality desired"
        }
      }
    }
  }' | jq .
```
