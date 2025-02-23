echo off

REM Install the Ollama Docker container
set /p answer=Do you want to install Ollama (y/N)? 

if /i "%answer%" EQU "Y" (
  echo Installing Ollama as a Docker container...
  cd ollama
  CALL install.bat
  cd ..
) else (
  echo Not installing Ollama
)

set /p answer=Do you want to install NextCloud (y/N)? 

if /i "%answer%" EQU "Y" (
  echo Installing NextCloud as a Docker container...
  cd nextcloud
  CALL install.bat
  cd ..
) else (
  echo Not installing NextCloud
)

set /p answer=Do you want to install nginx reverse-proxy (y/N)? 

if /i "%answer%" EQU "Y" (
  echo Installing nginx reverse-proxy as a Docker container...
  cd nginx-reverse-proxy
  CALL install.bat
  cd ..
) else (
  echo Not installing nginx reverse-proxy
)

set /p answer=Do you want to install home-assistant (y/N)? 

if /i "%answer%" EQU "Y" (
  echo Installing home-assistant as a Docker container...
  cd home-assistant
  CALL install.bat
  cd ..
) else (
  echo Not installing home-assistant
)
