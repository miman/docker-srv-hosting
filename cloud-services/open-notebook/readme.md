# Open Notebook

[Open Notebook](https://github.com/lfnovo/open-notebook) is an open-source, self-hosted alternative to Google's NotebookLM. It lets you upload documents, chat with AI about your content, generate notes, and create podcasts — all with complete data privacy and control.

## Features

- **Multi-Provider AI:** Supports 18+ AI providers (OpenAI, Gemini, Anthropic, Ollama, OpenRouter, etc.)
- **Document Intelligence:** Upload PDFs, text, and other documents, then chat with them
- **Podcast Generation:** Create AI-generated podcasts from your research
- **Privacy First:** Self-hosted, your data never leaves your server
- **Local AI Support:** Works fully offline with Ollama for 100% private usage

## Architecture

Open Notebook runs a two-container stack:
1. **Open Notebook App:** Streamlit-based web UI + FastAPI backend
2. **SurrealDB:** Document database for storing notebooks, sources, and configurations

## Ports Map

- **Web UI:** `4510` (maps to internal `8502`)
- **API:** `4511` (maps to internal `5055`)

## Persistent Storage

- **SurrealDB Data:** `${DOCKER_FOLDER}/open-notebook/surreal_data`
- **Notebook Data (uploads, etc.):** `${DOCKER_FOLDER}/open-notebook/notebook_data`

## Quick Start

1. Run `install.sh` to configure credentials, pull images, and start the containers.
2. Open the Web UI at [http://localhost:4510](http://localhost:4510).
3. On first login, click OK to set up the database schema.
4. Go to **Manage → Models** to add AI provider credentials (Ollama, OpenAI, etc.).
5. Create a notebook and start adding sources!

## Ollama Integration

If you have Ollama running from the `ai/ollama` folder in this project, set the Ollama base URL to:
- `http://host.docker.internal:11434` (if Ollama runs directly on the host)

Or configure it through the Open Notebook UI under Manage → Models → Add Credential → Ollama.

## Environment Variables

Key settings in `.env`:
- `ENCRYPTION_KEY` — Required. Used to encrypt stored API credentials.
- `SURREAL_PASSWORD` — SurrealDB root password.
- `OLLAMA_API_BASE` — Optional. URL to your Ollama instance.
- `OPENAI_API_KEY`, `GEMINI_API_KEY`, etc. — Optional provider API keys.
