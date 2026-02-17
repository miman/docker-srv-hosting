@echo off
setlocal enabledelayedexpansion

REM List of services and their install scripts
set SERVICES=Ollama open-webui watchtower NextCloud nginx-reverse-proxy home-assistant immich portainer glance-dashboard headscale traccar vaultwarden docmost

for %%S in (%SERVICES%) do (
  set "FOLDER=%%S"
  set "SCRIPT=install.bat"
  set "SERVICE_PROMPT=%%S"
  if /I "%%S"=="nginx-reverse-proxy" set "SERVICE_PROMPT=nginx reverse-proxy"
  if /I "%%S"=="glance-dashboard" set "SERVICE_PROMPT=Glance Dashboard"
  if /I "%%S"=="home-assistant" set "SERVICE_PROMPT=Home Assistant"
  if /I "%%S"=="nextcloud" set "SERVICE_PROMPT=Nextcloud"
  if /I "%%S"=="ollama" set "SERVICE_PROMPT=Ollama"
  if /I "%%S"=="open-webui" set "SERVICE_PROMPT=Open WebUI"
  if /I "%%S"=="immich" set "SERVICE_PROMPT=Immich"
  if /I "%%S"=="portainer" set "SERVICE_PROMPT=Portainer srv, question for agent will come later"
  if /I "%%S"=="headscale" set "SERVICE_PROMPT=Headscale"
  if /I "%%S"=="traccar" set "SERVICE_PROMPT=Traccar"
  if /I "%%S"=="vaultwarden" set "SERVICE_PROMPT=Vaultwarden"
  if /I "%%S"=="docmost" set "SERVICE_PROMPT=Docmost"
  if /I "%%S"=="registry" set "SERVICE_PROMPT=Registry"
  if /I "%%S"=="watchtower" set "SERVICE_PROMPT=Watchtower"
  
  set /p "answer=Do you want to install !SERVICE_PROMPT! (y/N)? "
  if /i "!answer!" EQU "Y" (
    echo Installing !SERVICE_PROMPT! as a Docker container...
    cd !FOLDER!
    if exist !SCRIPT! CALL !SCRIPT!
    cd ..
  ) else (
    echo Not installing !SERVICE_PROMPT!
  )
  set "answer="
)

REM Ask for Portainer Agent
set /p "answer=Do you want to install Portainer Agent (y/N)? "
if /i "%answer%" EQU "Y" (
  echo Installing Portainer Agent as a Docker container...
  cd portainer\portainer-agent
  if exist install-portainer-agent.bat CALL install-portainer-agent.bat
  cd ..\..
) else (
  echo Not installing Portainer Agent
)
