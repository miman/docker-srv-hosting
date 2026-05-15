@echo off
setlocal enabledelayedexpansion

REM List of services and their install scripts
set SERVICES=ai\ollama ai\open-webui infrastructure\watchtower cloud-services\nextcloud cloud-services\nextcloud-aio infrastructure\nginx-reverse-proxy cloud-services\home-assistant cloud-services\immich infrastructure\portainer cloud-services\glance-dashboard infrastructure\headscale cloud-services\traccar cloud-services\vaultwarden cloud-services\docmost infrastructure\registry development\verdaccio cloud-services\linux-in-docker ai\searxng ai\comfy_ui cloud-services\synapse

for %%S in (%SERVICES%) do (
  set "FOLDER=%%S"
  set "SCRIPT=install.bat"
  
  REM Extract the folder name only for prompting
  for %%F in (%%S) do set "SERVICE_PROMPT=%%~nxF"
  
  if /I "!SERVICE_PROMPT!"=="nginx-reverse-proxy" set "SERVICE_PROMPT=nginx reverse-proxy"
  if /I "!SERVICE_PROMPT!"=="glance-dashboard" set "SERVICE_PROMPT=Glance Dashboard"
  if /I "!SERVICE_PROMPT!"=="home-assistant" set "SERVICE_PROMPT=Home Assistant"
  if /I "!SERVICE_PROMPT!"=="nextcloud" set "SERVICE_PROMPT=Nextcloud"
  if /I "!SERVICE_PROMPT!"=="nextcloud-aio" set "SERVICE_PROMPT=Nextcloud AIO"
  if /I "!SERVICE_PROMPT!"=="ollama" set "SERVICE_PROMPT=Ollama"
  if /I "!SERVICE_PROMPT!"=="open-webui" set "SERVICE_PROMPT=Open WebUI"
  if /I "!SERVICE_PROMPT!"=="immich" set "SERVICE_PROMPT=Immich"
  if /I "!SERVICE_PROMPT!"=="portainer" set "SERVICE_PROMPT=Portainer srv, question for agent will come later"
  if /I "!SERVICE_PROMPT!"=="headscale" set "SERVICE_PROMPT=Headscale"
  if /I "!SERVICE_PROMPT!"=="netbird" set "SERVICE_PROMPT=Netbird"
  if /I "!SERVICE_PROMPT!"=="traccar" set "SERVICE_PROMPT=Traccar"
  if /I "!SERVICE_PROMPT!"=="vaultwarden" set "SERVICE_PROMPT=Vaultwarden"
  if /I "!SERVICE_PROMPT!"=="docmost" set "SERVICE_PROMPT=Docmost"
  if /I "!SERVICE_PROMPT!"=="registry" set "SERVICE_PROMPT=Registry"
  if /I "!SERVICE_PROMPT!"=="watchtower" set "SERVICE_PROMPT=Watchtower"
  if /I "!SERVICE_PROMPT!"=="synapse" set "SERVICE_PROMPT=Synapse"
  if /I "!SERVICE_PROMPT!"=="verdaccio" set "SERVICE_PROMPT=Verdaccio"
  if /I "!SERVICE_PROMPT!"=="linux-in-docker" set "SERVICE_PROMPT=Linux in Docker"
  if /I "!SERVICE_PROMPT!"=="searxng" set "SERVICE_PROMPT=SearXNG"
  
  set /p "answer=Do you want to install !SERVICE_PROMPT! (y/N)? "
  if /i "!answer!" EQU "Y" (
    echo Installing !SERVICE_PROMPT! as a Docker container...
    pushd !FOLDER!
    if exist !SCRIPT! CALL !SCRIPT!
    popd
  ) else (
    echo Not installing !SERVICE_PROMPT!
  )
  set "answer="
)

REM Ask for Portainer Agent
set /p "answer=Do you want to install Portainer Agent (y/N)? "
if /i "%answer%" EQU "Y" (
  echo Installing Portainer Agent as a Docker container...
  pushd infrastructure\portainer\portainer-agent
  if exist install-portainer-agent.bat CALL install-portainer-agent.bat
  popd
) else (
  echo Not installing Portainer Agent
)
