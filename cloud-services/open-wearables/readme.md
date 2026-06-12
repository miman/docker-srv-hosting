# Open Wearables Self-Hosted Platform

[Open Wearables](https://openwearables.io/) is an open-source, self-hosted health intelligence platform that unifies activity and health data from multiple wearable devices (Apple Health, Garmin, Whoop, Oura, Polar, Suunto, Strava, etc.) into a single, standardized, and AI-ready API.

## Features

- **Unified API & Schema:** Access metrics from different wearable providers using a single standardized REST API.
- **Data Privacy & Control:** Retain full ownership of your sensitive health and biometric data.
- **Background Syncing:** Scheduled Celery tasks fetch and process wearable data periodically.
- **AI-Ready:** Built-in support for the Model Context Protocol (MCP) so AI agents can reason over your biometrics.
- **Webhook Subscriptions:** Dispatch real-time events to other systems using Svix.

## Architecture

Open Wearables runs a multi-container stack:
1. **Frontend Dashboard:** A React-based developer portal for auth flows and configuration.
2. **Backend API:** FastAPI backend doing the heavy lifting, data ingestion, and OAuth management.
3. **Database (PostgreSQL):** Relational store for configurations, users, and metrics.
4. **Cache & Broker (Redis):** Celery task broker and backend caching.
5. **Celery Worker & Beat:** Background task processors.
6. **Celery Flower:** Monitoring dashboard for background tasks.
7. **Svix Server:** Manages outgoing webhooks reliably.

## Ports Map

- **Frontend Dashboard:** `4415` (maps to internal container `3000`)
- **Backend API:** `4416` (maps to internal container `8000`)
- **Celery Flower:** `4417` (maps to internal container `5555`)

## Persistent Storage

- **PostgreSQL Data:** `${DOCKER_FOLDER}/open-wearables/postgres-data`
- **Redis Cache:** `${DOCKER_FOLDER}/open-wearables/redis`

## Quick Start

1. Edit the environment settings in `.env` if you need to configure specific wearable API client credentials.
2. Run `install.sh` to fetch the source repository, configure endpoints, build local images, and start the containers.
3. Open the Frontend Dashboard at [http://localhost:4415](http://localhost:4415) (or your domain).
4. Log in using the admin account:
   - **Email:** `admin@admin.com`
   - **Password:** (Automatically generated and displayed in `install.sh` output, saved in `.env` under `ADMIN_PASSWORD`)

