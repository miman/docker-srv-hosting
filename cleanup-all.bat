echo off

REM This scripts removes all created docker containers, networks & volumes

REM OBS, this file will remove all volumes as well, if you want to keep these remove the -v flags in the rows below or run the cleanup.bat script

echo Running this will remove all Docker containers as well as all volumes creted by this project
set /p "confirm=Do you really want to delete all Docker containers & volumes? (y/N): "

if /i "%confirm%" neq "y" (
    echo Aborting script.
    exit /b 1
) else (
  REM Uninstall the home-assistant Docker container
  cd home-assistant
  call cleanup-all.bat
  cd ..

  REM Uninstall the ollama Docker container
  cd ollama
  call cleanup-all.bat
  cd ..

  REM Uninstall the nextcloud Docker container
  cd nextcloud
  call cleanup-all.bat
  cd ..

  REM Uninstall the nginx-reverse-proxy Docker container
  cd nginx-reverse-proxy
  call cleanup-all.bat
  cd ..
)