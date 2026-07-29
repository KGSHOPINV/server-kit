---
sidebar_position: 6
title: AI Stack
---

# Local AI Stack

Run AI models on your own server — no API keys, no subscriptions, no data leaves your machine.

---

## The Stack

| Service | Port | What It Does |
|---------|------|-------------|
| **Ollama** | `:11434` | Runs AI models — the engine |
| **Open WebUI** | `:3004` | ChatGPT-like interface for chatting with models |
| **OpenClaw** | `:3005` | Autonomous AI agent — can plan, execute, and iterate |

### How They Connect

```
You (browser)
   │
   ├──→ Open WebUI (:3004)  ──→ Ollama (:11434) ──→ AI Model
   │    (chat interface)         (model runner)       (in memory)
   │
   └──→ OpenClaw (:3005)    ──→ Ollama (:11434) ──→ AI Model
        (AI agent)               (model runner)       (in memory)
```

Open WebUI and OpenClaw both talk to Ollama. Ollama manages loading/unloading models from RAM.

---

## RAM Requirements

AI models load into RAM when you use them. This is the main thing to plan for.

| Model | Size on Disk | RAM Needed | Quality |
|-------|-------------|------------|---------|
| Gemma 4 2B | ~1.5 GB | ~4 GB | Good for basics |
| Llama 3.1 8B | ~4.7 GB | ~8 GB | Good all-rounder |
| Mistral 7B | ~4.1 GB | ~8 GB | Good for code |
| Gemma 4 12B | ~7 GB | ~12 GB | Great quality |
| Gemma 4 31B | ~18 GB | ~24 GB | Best quality |

:::info Models unload automatically
Ollama loads a model into RAM when you chat with it and **unloads after ~5 minutes of inactivity**. So it doesn't permanently eat your RAM — only while actively chatting.
:::

### Can I Run AI + Other Docker Services?

**Yes.** Your other containers (NPM, Portainer, Uptime Kuma, etc.) use ~2-3 GB RAM combined. They're lightweight.

| Total Server RAM | Recommended Model | Room for Docker Services? |
|-----------------|-------------------|--------------------------|
| 8 GB | Gemma 4 2B | Tight but works |
| 16 GB | Llama 3.1 8B | Yes, comfortable |
| 32 GB | Gemma 4 12B | Yes, plenty of room |
| 64 GB+ | Gemma 4 31B | Yes, run anything |

If RAM gets tight, Ollama gets slower (swaps to disk) — it won't crash your other services.

---

## Managing Models

### CLI Tool

```bash
ai-models
```

Interactive menu to list, pull, remove, and chat with models.

### Direct Commands

```bash
# List installed models
docker exec ollama ollama list

# Pull a new model
docker exec ollama ollama pull gemma4:12b

# Remove a model
docker exec ollama ollama rm gemma4:2b

# Chat in terminal
docker exec -it ollama ollama run gemma4:12b

# Check RAM usage
docker stats ollama --no-stream
```

### Popular Models

| Model | Command | Good For |
|-------|---------|----------|
| Gemma 4 2B | `ollama pull gemma4:2b` | Quick answers, low RAM |
| Gemma 4 12B | `ollama pull gemma4:12b` | Best balance of speed and quality |
| Gemma 4 31B | `ollama pull gemma4:31b` | Highest quality (needs lots of RAM) |
| Llama 3.1 8B | `ollama pull llama3.1:8b` | General purpose, good all-rounder |
| Llama 3.1 70B | `ollama pull llama3.1:70b` | Very large, needs GPU |
| Mistral 7B | `ollama pull mistral:7b` | Great for code and reasoning |
| CodeLlama 7B | `ollama pull codellama:7b` | Coding specific |
| Phi-3 Mini | `ollama pull phi3:mini` | Very small and fast |

---

## GPU Acceleration

If you have an **NVIDIA GPU**, the setup script can install the NVIDIA Container Toolkit for GPU acceleration. This makes models run significantly faster.

```bash
# Check if GPU is being used
docker exec ollama nvidia-smi
```

AMD GPUs work with Ollama but require manual ROCm setup.

---

## Open WebUI Tips

- **Create an account** on first visit — this is local-only, no external auth
- **Select a model** from the dropdown before chatting
- **System prompts** — set custom instructions per chat
- **File uploads** — drag files into the chat
- **Multiple chats** — keep different conversations going

---

## Troubleshooting

### Model won't load
```bash
# Check Ollama logs
docker logs ollama

# Usually means not enough RAM — try a smaller model
docker exec ollama ollama pull gemma4:2b
```

### Open WebUI can't connect to Ollama
```bash
# Check both are on the same network
docker network inspect proxy | grep -A2 ollama
docker network inspect proxy | grep -A2 open-webui

# Restart both
cd /srv/docker/ai && docker compose restart
```

### Very slow responses
- Check RAM: `free -h` — if swap is being used heavily, model is too large
- Try a smaller model
- Close unused models: they auto-unload after 5 min of idle
