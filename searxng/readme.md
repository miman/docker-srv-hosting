# SearXNG - Privacy-Respecting Metasearch Engine

SearXNG is a free internet metasearch engine which aggregates results from more than 70 search services. It doesn't track its users and doesn't share anything with a third party.

In this setup, SearXNG is used as a backend for tools like **Open WebUI** to provide real-time web search capabilities to local LLMs.

## Installation & Running

To deploy SearXNG, you can use the provided installation script:

```bash
./install.sh
```

Or run it directly using Docker Compose:

```bash
docker compose up -d
```

Once running, SearXNG will be accessible at: `http://localhost:4522`

---

# Connect SearXNG to Open WebUI

Now you need to tell your local AI how to talk to the SearXNG search engine you just started.

### 1. Open the Admin Panel
Click on your profile icon in the bottom-left corner of Open WebUI → Select **Admin Panel** → **Settings** → **Web Search**.

### 2. Enable Web Search
Toggle the **Enable Web Search** switch to **ON**.

### Configure Search Engine:

Search Engine: Select searxng from the dropdown menu.

SearXNG Query URL: This is the most important part. Since both are likely running in Docker, use this address:

```plaintext
http://host.docker.internal:8080/search?q=<query>
```

Note: If host.docker.internal doesn't work on your Ubuntu setup, replace it with your computer's local IP (e.g., http://192.168.1.XX:8080/search?q=<query>).

### Optimize Search Settings (Optional but Recommended):

Search Result Count: Set this to 3 or 5. Fetching too many pages can slow down your GPU if the context gets too large.

Concurrent Requests: Set this to 10 for faster searching.

### Save:

Scroll down and click Save.