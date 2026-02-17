# Ollama

Ollama is a tool for running and managing large language models locally.

This folder contains an install script to deploy **_Ollama_** & optionally **_OpenWebUI_** on Docker on your local machine.

## Ollama server

This installs the actual server that can run local models, this is also used by many of the other tools in this project.

More information about Ollama can be found here: https://ollama.com/

The list of models that can be used can be found here: https://ollama.com/library

The models downloaded to your Ollama server will be placed on a separate Docker volume called **_ollama_**, so they are kept even if you delete the container & reinstalls a newer version.

The Ollama srv docker image is configured to use you NVidia GPU for faster inference.

### For Mac users

While Mac doesn't support that Docker uses the GPU, running Ollama as a docker container on a Mac is very slow so I propose to install ollama-desktop for Mac.

Can be found here: https://ollama.com/download/mac
