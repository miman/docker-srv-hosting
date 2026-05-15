@echo off
set /p CONFIG_PATH=Enter the absolute path to the config folder to use for Vaultwarden data: 

REM Replace backslashes with forward slashes for Docker compatibility
set "CONFIG_PATH=%CONFIG_PATH:\=/%"

set /p DOMAIN=Enter the domain for Vaultwarden (e.g. https://vw.domain.tld), or leave blank for none: 

docker pull vaultwarden/server:latest

set "DOMAIN_ARG="
if not "%DOMAIN%"=="" set "DOMAIN_ARG=--env DOMAIN=%DOMAIN% "

REM Run the Vaultwarden container
docker run -d ^
  --name vaultwarden ^
  %DOMAIN_ARG%^
  -v %CONFIG_PATH%:/data ^
  --restart unless-stopped ^
  -p 4410:80 ^
  vaultwarden/server:latest

echo "Vaultwarden is now running. You can access it at http://localhost:4410"