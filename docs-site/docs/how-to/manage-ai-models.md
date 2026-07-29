---
sidebar_position: 8
title: Manage AI Models
---

# How Do I Manage AI Models?

---

## Quick Start

```bash
ai-models
```

Interactive menu: list, pull, remove, chat.

## Pull a Model

```bash
docker exec ollama ollama pull gemma4:12b
```

## List Installed Models

```bash
docker exec ollama ollama list
```

## Remove a Model

```bash
docker exec ollama ollama rm gemma4:2b
```

## Chat in Terminal

```bash
docker exec -it ollama ollama run gemma4:12b
```

Type your message, press Enter. Type `/bye` to exit.

## Chat in Browser

Open WebUI at `http://YOUR-IP:3004`:
1. Create an account (first visit)
2. Select a model from the dropdown
3. Start chatting

## Check RAM Usage

```bash
docker stats ollama --no-stream
```

If it's using too much RAM, try a smaller model.

## Model Recommendations

| Your RAM | Best Model | Why |
|----------|-----------|-----|
| 8 GB | `gemma4:2b` | Only one that fits comfortably |
| 16 GB | `llama3.1:8b` | Good all-rounder, leaves room for Docker |
| 32 GB | `gemma4:12b` | Best quality/speed balance |
| 64 GB+ | `gemma4:31b` | Highest quality available |
