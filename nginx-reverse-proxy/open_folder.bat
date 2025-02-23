echo off

call ../scripts/set-DOCKER_FOLDER.bat

set LOCAL_FOLDER=%DOCKER_FOLDER%\nginx-reverse-proxy_reverse-proxy\_data

REM Open the code folder in Windows Explorer
explorer %LOCAL_FOLDER%
