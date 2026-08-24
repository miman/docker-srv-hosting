# Mealie Recipe & Meal Planner

[Mealie](https://mealie.io/) is a self-hosted recipe manager and meal planner with a REST API and a web application built using Vue. Easily import recipes from websites, plan meals, generate shopping lists, and customize your instance.

## Features

- **Recipe Management:** Import recipes automatically from URLs or create your own custom recipes.
- **Meal Planning:** Organize daily, weekly, or monthly meal plans.
- **Shopping Lists:** Automatically compile itemized shopping lists based on scheduled meal plans.
- **Lightweight SQLite Engine:** Uses an embedded SQLite database engine for minimal resource usage.
- **REST API & Webhooks:** Rich API capabilities for integration with third-party automation tools.

## Architecture

Mealie runs as a single-container service:
1. **Mealie App Container (`mealie`):** Unified web application, API server, and SQLite database running on port `4418`.

## Ports Map

- **Mealie Web Interface / API:** `4418` (maps to internal container `9000`)

## Persistent Storage

- **Mealie Application & Database Data:** `${DOCKER_FOLDER}/mealie/data`

## Quick Start

1. Run `install.sh` to initialize persistent directories, configure your host endpoint (`BASE_URL`), pull images, and launch the container.
2. Open Mealie in your browser at [http://localhost:4418](http://localhost:4418) (or your domain).
3. Log in with the default administrator credentials:
   - **Email / Username:** `admin@example.com`
   - **Password:** `MyPassword123`
4. **Important:** Change the administrator password in user settings immediately after logging in for the first time.
