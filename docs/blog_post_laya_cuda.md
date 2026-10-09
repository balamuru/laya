# Stop Using 8B Generative LLMs for Routing: The Rise of System 1 AI with Jev and Laya

*Understanding the split between System 1 and System 2 AI, why TypeSafe Jev pioneered programmable decisions, where Laya improves upon it, its objective trade-offs, and how to self-host with CUDA on modest hardware.*

---

## 1. The Cognitive Split: System 1 vs. System 2 in AI

In his seminal work *Thinking, Fast and Slow*, psychologist Daniel Kahneman divided human cognition into two distinct operating modes:

- **System 1 (Fast & Intuitive):** Instantaneous, automatic, probabilistic, and subconscious pattern matching. It’s what lets you duck when a ball flies toward your face, instantly recognize an angry voice, or effortlessly categorize an object in milliseconds without deliberating.
- **System 2 (Slow & Deliberative):** Conscious, sequential, reflective, and resource-heavy. It’s what you engage when computing $37 \times 49$, writing an essay, or playing tournament chess.

### The Problem with Modern AI Stacks

Over the last few years, the software industry has **over-indexed on System 2 for every conceivable problem**.

When an agent needs to decide:
> *"Does this incoming email belong to Support, Billing, or Sales?"*

The standard reflex today is to invoke an 8-billion or 70-billion parameter generative autoregressive model (like Llama 3 or Qwen via Ollama), pass a 400-token prompt begging for JSON output, and wait **800ms to 2,500ms** while an autoregressive token-generation loop churns through gigabytes of VRAM.

This is architectural overkill. Ticket classification, tool-calling validation, guardrails, and intent routing are fundamentally **System 1 tasks**. They do not require a generative language model writing paragraphs token-by-token; they require rapid, deterministic, calibrated probability judgments over discrete choices.

---

## 2. Enter TypeSafe Jev: The Pioneer of Programmable System 1

The breakthrough concept of turning System 1 intuition into composable software primitives was pioneered by **TypeSafe** with their flagship model, **Jev**.

Instead of interacting with AI as an unstructured chat interface, TypeSafe introduced a paradigm where models output **typed judgments** rather than conversational text:

- **`choice`**: Selecting one option among distinct criteria, returning a mathematically calibrated probability distribution over all options.
- **`score`**: Continuous scalar scoring across ordered dimensions (e.g. urgency from 0 to 2).
- **`noul`**: Binary boolean judgments (yes/no) with explicit confidence measures.

Jev established the standard wire protocol (`POST /v1/systemone`) and demonstrated that software can use AI decisions just like programming primitives: fast, composable, and structured.

However, native Jev was designed primarily as a cloud-hosted API. In high-frequency production loops—where an autonomous agent might make 10 to 20 routing decisions per workflow—relying solely on cloud endpoints presents distinct challenges: network latency round-trips, data privacy/residency concerns, and metered API costs.

---

## 3. Where Laya Improves on Jev

Created by **Nandha Kishor M** and the team at **ConvAI Innovations**, [**Laya**](https://github.com/NandhaKishorM/laya) is an open-source, multilingual, non-autoregressive decision engine built to take the System 1 vision to its logical conclusion: **in-process, on-device, and completely local**.

Laya is deliberately designed to be **wire-compatible** with Jev’s `/v1/systemone` specification, meaning any SDK or integration written for Jev can switch its `baseUrl` to Laya with zero code changes.

Where Laya pushes the envelope:

### 1. Zero Cloud Latency (14ms vs. 250ms+)
Cloud APIs must pay the network tax (DNS resolution, TLS handshakes, queue time, internet routing). Native cloud Jev has a published P50 latency of **~236ms – 276ms**. Running Laya locally on a consumer GPU executes a single ModernBERT forward pass in **13ms to 14ms**—a **~17x speedup**. If an agent makes 10 decisions in an execution loop, local Laya finishes in 140ms total instead of 2.5 seconds of dead network wait time.

### 2. Complete Data Sovereignty & Air-Gapped Privacy
In healthcare (HIPAA), financial compliance (FINRA), defense, or confidential enterprise workflows, sending raw user state to external cloud endpoints is often a non-starter. Laya runs entirely inside your own container or process; zero bytes of user data ever leave your machine.

### 3. Predictable Zero-Cost Scaling
High-velocity classification pipelines can quickly rack up per-token API bills on commercial hosted providers. Laya runs unmetered on your existing hardware.

### 4. Modern Foundations & Calibration
Laya builds upon modern bidirectional encoder backbones (**ModernBERT** for English and **mmBERT** for multilingual support) equipped with reinforcement-learned decision heads trained via RLCD (Reinforcement Learning against Strictly Proper Scoring Rules). This ensures that output probabilities genuinely reflect mathematical confidence rather than heuristic guesses.

---

## 4. An Objective Look: Laya's Shortcomings & Trade-offs

No technology is a silver bullet. To evaluate Laya objectively against both TypeSafe Jev and generative models (Ollama/LLMs), developers must understand its genuine constraints:

### 1. No Generative Synthesis or Reasoning
Laya is strictly a decision classifier and scorer. It **cannot** summarize a document, draft an email, generate code, or conduct multi-step chain-of-thought mathematical proofs. If your task requires creating new text, you still need a generative model.

### 2. Context Window Limits
Because Laya uses bidirectional encoder backbones (ModernBERT), its context window is bounded:
- English checkpoint: default **1,024 tokens**.
- Multilingual checkpoint: up to **8,192 tokens** with `max_len=8192`.
While this is ample for customer tickets, database rows, and agent observation states, it cannot ingest a 100,000-token PDF transcript in a single pass like modern 1M-context decoder LLMs.

### 3. Multilingual Accuracy Spread
While `laya-multilingual` covers over 100 languages, its accuracy on low-resource languages reflects the inherent trade-off of a compact encoder model. On the 51-language MASSIVE intent benchmark (20 options):
- High-resource languages (English, German, Spanish): **82% – 95% accuracy**.
- Macro-average across all 51 languages: **~40.1% accuracy** (compared to random baseline of 5%).
Massive 70B+ cloud LLMs will outperform compact encoders on obscure dialects.

### 4. Operational Self-Hosting Overhead
With managed cloud APIs like TypeSafe Jev, infrastructure scaling, high availability, and hardware health are managed for you. With Laya, you are responsible for container deployment, GPU driver compatibility, and memory allocation.

### 5. Dependency on Criteria Clarity
Laya's precision depends heavily on how well questions and criteria are articulated. If candidate options are ambiguous, overlapping, or poorly defined, calibration degrades.

---

## 5. Architectural Comparison Matrix

| Dimension | Laya (Local CUDA) | TypeSafe Jev (Cloud) | Ollama (Llama-3-8B) |
|---|---|---|---|
| **Cognitive Category** | **System 1 (Intuitive)** | **System 1 (Intuitive)** | **System 2 (Deliberative)** |
| **Model Architecture** | Bidirectional Encoder + RL Heads | Dedicated System 1 Model | Autoregressive Decoder |
| **P50 Latency** | **13ms – 14ms** | **236ms – 276ms** | **850ms – 1,800ms** |
| **Execution Location** | 100% Local / On-Device | Cloud (api.typesafe.ai) | Local Docker / Host |
| **Hardware Required** | Modest 8 GB GPU or CPU | None (Hosted API) | 8 GB – 16 GB GPU |
| **VRAM Consumption** | **~1.4 GB – 1.8 GB** | 0 MB (Remote) | 6.0 GB – 16.0 GB |
| **Output Type** | Structured probabilities & scores | Structured probabilities & scores | Text strings (parsed as JSON) |
| **Data Privacy** | Air-gapped / Zero egress | Data sent to cloud API | Air-gapped / Local |
| **Max Context** | 1,024 – 8,192 tokens | Varies by primitive | 8k – 128k tokens |
| **Cost Model** | $0.00 (Self-hosted) | Metered API billing | $0.00 (Self-hosted) |

---

## 6. Practical AI on Modest Hardware

A common misconception in local AI is that you need expensive enterprise hardware—an RTX 4090 with 24 GB VRAM or an A100—to run production-grade intelligence.

Laya completely dispels this myth:
- **Modest Consumer GPUs (8 GB VRAM):** In our test setup on an **NVIDIA GeForce RTX 2080 (8 GB)**, Laya runs with FP16 precision using just **1.8 GB of VRAM**. This leaves more than 4 GB of free VRAM for your desktop GUI, IDEs, and browser windows, while delivering **sub-15ms inference**.
- **CPU Execution:** Even on machines without any GPU (standard Intel/AMD laptops or Apple Silicon Macs), Laya runs natively in **30ms to 50ms**.
- **Edge Devices & Small VPS:** A $10/month cloud VPS or an Intel NUC mini-PC can effortlessly serve 50+ decision requests per second.

---

## 7. Containerizing Laya with CUDA

Deploying Laya with GPU acceleration is straightforward using Docker. 

### Multi-Stage Dockerfile Overview

```dockerfile
ARG PYTHON_IMAGE=python:3.11-slim-trixie

FROM ${PYTHON_IMAGE} AS build
RUN python -m venv --upgrade-deps /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

ARG TORCH_INDEX=cu130
ARG TORCH_VERSION=2.14.0
RUN pip install "torch==${TORCH_VERSION}" \
    --index-url https://download.pytorch.org/whl/${TORCH_INDEX}
RUN pip install ".[serve]"

FROM ${PYTHON_IMAGE} AS runtime
ENV PATH="/opt/venv/bin:$PATH" \
    TORCH_DISABLE_NATIVE_JIT=1 \
    LAYA_DEVICE=cuda

COPY --from=build /opt/venv /opt/venv
ENTRYPOINT ["python", "/opt/laya/entrypoint.py"]
CMD ["laya-serve"]
```

> **Crucial Tip (`TORCH_DISABLE_NATIVE_JIT=1`):**  
> PyTorch 2.14 attempts to replace eager CUDA operations with Triton kernels compiled on the first inference pass. Compiling Triton requires a C compiler that slim container images don't carry. Setting `TORCH_DISABLE_NATIVE_JIT=1` ensures stable execution using stock CUDA kernels with zero performance penalty.

### Avoiding the 8 GB VRAM Trap

If Laya boots with default settings on an 8 GB consumer GPU where the desktop environment already occupies 2.3 GB of VRAM, preloading all three model checkpoints simultaneously will exhaust the remaining memory and trigger CPU fallback.

To ensure 100% GPU execution with ample headroom, configure three environment variables:
1. `LAYA_MAX_LOADED=1` (Keeps at most 1 model resident in VRAM at a time).
2. `LAYA_CUDA_AMP=fp16` (Enables half-precision autocast, halving activation memory).
3. `LAYA_MODELS=english` (Preloads only the model you actively need).

This lowers container VRAM from **4,810 MiB** down to **1,834 MiB** (**62% memory reduction**), leaving over 4 GB of free headroom on an 8 GB card.

---

## 8. Deployment: Docker Compose & Pre-Built Images (CUDA & CPU)

You don't need to compile PyTorch or build from source; pre-built images are published on Docker Hub for both GPU and CPU:

```bash
# GPU-accelerated (PyTorch CUDA 13.0, NVIDIA Container Toolkit)
docker pull vinaybalamuru/laya:cuda

# Lightweight CPU-only build (~371 MB compressed, zero GPU drivers needed)
docker pull vinaybalamuru/laya:cpu
```

> **Official Docs:** For additional deployment options (including ModelScope offline baking and ARM64/Apple Silicon), consult the official documentation at [nandhakishorm.github.io/laya/docker/](https://nandhakishorm.github.io/laya/docker/).

### 1. Unified `.env` Configuration

Both stacks share a single companion `.env` file, isolating host port bindings and credentials:

```env
# Networking ports
LAYA_PORT=8111          # CUDA Server Host Port
LAYA_CPU_PORT=8112      # CPU Server Host Port
LAYA_BIND_ADDRESS=0.0.0.0

# Optional API key protection
LAYA_API_KEY=my-secret-laya-api-key

# Hardware & Memory optimization for 8 GB GPUs
LAYA_DEVICE=cuda
LAYA_GPU_ID=0
LAYA_CUDA_AMP=fp16
LAYA_MAX_LOADED=1
LAYA_MODELS=english
LAYA_PRELOAD=1

# CPU Stack configuration
LAYA_CPU_THREADS=4
LAYA_CPU_AMP=

# Optional Hugging Face Token (avoids download rate limits)
HF_TOKEN=hf_...
```

### 2. Dual Docker Compose Stacks

To prevent port and container collisions while sharing the downloaded weights cache, we provide two compose files:

#### A. CUDA Stack (`docker-compose/docker-compose.yml`)
```yaml
name: laya-cuda

services:
  laya-serve:
    image: vinaybalamuru/laya:cuda
    command: ["laya-serve"]
    ports:
      - "${LAYA_BIND_ADDRESS:-0.0.0.0}:${LAYA_PORT:-8111}:${LAYA_PORT:-8111}"
    environment:
      LAYA_HOST: "0.0.0.0"
      LAYA_PORT: "${LAYA_PORT:-8111}"
      LAYA_DEVICE: "cuda"
      LAYA_CUDA_AMP: "${LAYA_CUDA_AMP:-fp16}"
      LAYA_MAX_LOADED: "${LAYA_MAX_LOADED:-1}"
      LAYA_MODELS: "${LAYA_MODELS:-english}"
      LAYA_PRELOAD: "${LAYA_PRELOAD:-1}"
      LAYA_API_KEY: "${LAYA_API_KEY:-}"
      HF_TOKEN: "${HF_TOKEN:-}"
    volumes:
      - model-cache:/home/laya/.cache/huggingface
    deploy:
      resources:
        reservations:
          devices:
            - driver: nvidia
              device_ids: ["${LAYA_GPU_ID:-0}"]
              capabilities: [gpu]
    restart: unless-stopped
    init: true

volumes:
  model-cache:
    name: laya_model-cache
```

#### B. CPU Stack (`docker-compose/docker-compose.cpu.yml`)
```yaml
name: laya-cpu

services:
  laya-serve:
    image: vinaybalamuru/laya:cpu
    command: ["laya-serve"]
    ports:
      - "${LAYA_BIND_ADDRESS:-0.0.0.0}:${LAYA_CPU_PORT:-8112}:${LAYA_CPU_PORT:-8112}"
    environment:
      LAYA_HOST: "0.0.0.0"
      LAYA_PORT: "${LAYA_CPU_PORT:-8112}"
      LAYA_DEVICE: "cpu"
      LAYA_MAX_LOADED: "${LAYA_MAX_LOADED:-1}"
      LAYA_MODELS: "${LAYA_MODELS:-english}"
      LAYA_PRELOAD: "${LAYA_PRELOAD:-1}"
      LAYA_API_KEY: "${LAYA_API_KEY:-}"
      OMP_NUM_THREADS: "${LAYA_CPU_THREADS:-4}"
      HF_TOKEN: "${HF_TOKEN:-}"
    volumes:
      - model-cache:/home/laya/.cache/huggingface
    restart: unless-stopped
    init: true

volumes:
  model-cache:
    name: laya_model-cache
```

Notice that both services mount the same volume: `laya_model-cache`. Checkpoint weights downloaded once are instantly shared between the CPU and GPU daemons with zero redundancy.

Start either stack (or both side-by-side):
```bash
# Start CUDA daemon on port 8111:
docker compose --env-file docker-compose/.env -f docker-compose/docker-compose.yml up -d laya-serve

# Start CPU daemon on port 8112:
docker compose --env-file docker-compose/.env -f docker-compose/docker-compose.cpu.yml up -d laya-serve
```

---

## 9. Live Benchmark Comparison: CUDA vs. CPU vs. Native Jev vs. Cloud LLM

We benchmarked local containers (on an **NVIDIA GeForce RTX 2080** and an **Intel CPU with 4 threads**) directly against **Native TypeSafe Jev** (`api.typesafe.ai`) and OpenRouter's meta-router over identical state-and-criteria queries:

```text
========================================================================================================
                                LIVE COMPARATIVE BENCHMARK METRICS
========================================================================================================
 Engine / Backend                   Test Case                    Throughput     P50 Latency   Mean Latency
────────────────────────────────────────────────────────────────────────────────────────────────────────
 Laya CUDA (RTX 2080 GPU)           Single Classify (3 Criteria)  76.1 req/sec   13.09 ms      13.15 ms
 Laya CUDA (RTX 2080 GPU)           Multi-Question (3 Questions)  56.1 req/sec   17.04 ms      17.82 ms
────────────────────────────────────────────────────────────────────────────────────────────────────────
 Laya CPU (4 OpenMP Threads)        Single Classify (3 Criteria)   7.0 req/sec  143.46 ms     143.57 ms
 Laya CPU (4 OpenMP Threads)        Multi-Question (3 Questions)   2.8 req/sec  362.30 ms     362.92 ms
────────────────────────────────────────────────────────────────────────────────────────────────────────
 Native TypeSafe Jev (Cloud API)    Single Classify (3 Criteria)   5.0 req/sec  194.92 ms     199.16 ms
 Native TypeSafe Jev (Cloud API)    Multi-Question (3 Questions)   4.8 req/sec  194.18 ms     209.70 ms
────────────────────────────────────────────────────────────────────────────────────────────────────────
 OpenRouter Jev Meta-Router (LLM)   Single Classify (Azure/OpenAI)Cloud bound 1,858.00 ms   2,154.00 ms
========================================================================================================
```

### Key Takeaways:

1. **Local CUDA Delivers True Real-Time Performance:**
   At **13.09 ms P50**, Laya on a consumer GPU is **~15x faster** than native TypeSafe Jev over the cloud and **~140x faster** than an LLM meta-router. Zero network transit, zero TLS handshake, and zero cloud queueing.
2. **Native TypeSafe Jev is ~195ms, Not Seconds:**
   Testing directly with a TypeSafe API key against `api.typesafe.ai` confirms native Jev completes in **~195 ms P50**. The ~1.85-second latency observed on OpenRouter was due to OpenRouter treating Jev as a meta-router that routed downstream to Azure OpenAI (`openai/gpt-6-luna`), which ran an autoregressive text-generation loop.
3. **Local CPU Outperforms Cloud WAN Roundtrips for Single Inferences:**
   At **143.46 ms P50**, running Laya on an ordinary 4-thread CPU beats native cloud Jev (**194.92 ms**) for single decisions simply because it eliminates WAN network hops. On modest hardware without a GPU, local CPU execution is completely practical for interactive systems.
4. **Near-Zero Delta for Multi-Question Batching on GPU:**
   Evaluating 3 simultaneous hypothesis questions on CUDA takes **17.04 ms** (only a 3.95ms delta over single classification), showing how parallel option heads evaluate criteria concurrently in a single forward pass.

---

## 10. Conclusion

The future of AI architecture is not a monolithic model doing everything poorly; it is a collaborative pipeline where specialized models do what they do best:

- Use **Generative LLMs (Ollama, Claude, GPT)** for generative synthesis, creative prose, and deep deliberation.
- Use **System 1 Decision Engines (Jev, Laya)** for fast, deterministic, calibrated on-device routing, guardrails, and discrete classification.

Huge props to **Nandha Kishor M** and the contributors behind the [official Laya repository](https://github.com/NandhaKishorM/laya) for open-sourcing a principled, non-autoregressive alternative to brute-force prompting, and to **TypeSafe** for pioneering the System 1 paradigm.

To get started right away, pull the pre-built containers:
```bash
# For NVIDIA GPUs:
docker pull vinaybalamuru/laya:cuda

# For CPU-only servers:
docker pull vinaybalamuru/laya:cpu
```
