@echo off

REM List of services and their install scripts
set SERVICES=Ollama NextCloud nginx-reverse-proxy home-assistant immich portainer glance-dashboard headscale traccar vaultwarden docmost

for %%S in (%SERVICES%) do (
  set "FOLDER=%%S"
  set "SCRIPT=install.bat"
  if /I "%%S"=="nginx-reverse-proxy" set "PROMPT=nginx reverse-proxy"
  if /I "%%S"=="glance-dashboard" set "PROMPT=Glance Dashboard"
  if /I "%%S"=="home-assistant" set "PROMPT=Home Assistant"
  if /I "%%S"=="nextcloud" set "PROMPT=Nextcloud"
  if /I "%%S"=="ollama" set "PROMPT=Ollama"
  if /I "%%S"=="immich" set "PROMPT=Immich"
  if /I "%%S"=="portainer" set "PROMPT=Portainer srv, question for agent will come later"
  if /I "%%S"=="headscale" set "PROMPT=Headscale"
  if /I "%%S"=="traccar" set "PROMPT=Traccar"
  if /I "%%S"=="vaultwarden" set "PROMPT=Vaultwarden"
  if /I "%%S"=="docmost" set "PROMPT=Docmost"
  set /p answer=Do you want to install %PROMPT% (y/N)? 
  if /i "%answer%" EQU "Y" (
    echo Installing %PROMPT% as a Docker container...
    cd %FOLDER%
    if exist %SCRIPT% CALL %SCRIPT%
    cd ..
  ) else (
    echo Not installing %PROMPT%
  )
)

REM Ask for Portainer Agent
set /p answer=Do you want to install Portainer Agent (y/N)? 
if /i "%answer%" EQU "Y" (
  echo Installing Portainer Agent as a Docker container...
  cd portainer\portainer-agent
  if exist install-portainer-agent.bat CALL install-portainer-agent.bat
  cd ..\..
) else (
  echo Not installing Portainer Agent
)
