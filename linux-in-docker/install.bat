@echo off
set /p CONFIG_PATH=Enter the absolute path to the config folder to use for /config: 

REM Replace backslashes with forward slashes for Docker compatibility
set "CONFIG_PATH=%CONFIG_PATH:\=/%"

docker run -d ^
  --name=local-linux ^
  -p 3000:3000 ^
  -p 3001:3001 ^
  -e PUID=1000 ^
  -e PGID=1000 ^
  -e TZ=Europe/Stockholm ^
  -e DOCKER_MODS="linuxserver/mods:webtop-firefox,linuxserver/mods:webtop-vscode" ^
  -v %CONFIG_PATH%:/config ^
  --shm-size="1gb" ^
  --restart unless-stopped ^
  lscr.io/linuxserver/webtop:ubuntu-xfce