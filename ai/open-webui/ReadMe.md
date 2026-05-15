## Local WebUI for Ollama

[Open WebUI](https://github.com/open-webui/open-webui) is a open-source AI chat webui, for Ollama (default), LM Studio, Ooba, vLLM, OpenAI, and Anthropic compatible servers. It adapts to your workflow and works entirely offline.

More information can be found here: https://openwebui.com/

After installation you can run the Ollama WebUI here: [localhost:4512](http://localhost:4512)

OBS !

You need to change the Ollama connection URL to this if you run Ollama in docker:

`http://host.docker.internal:11434`

You find this setting by:

1. Click on your user icon
2. Select "Admin panel"
3. Click on Settings menu item
4. Select Connections

The config for this web app will be placed on a separate Docker volume called **_open-webui_**, so they are kept even if you delete the container & reinstalls a newer version.
