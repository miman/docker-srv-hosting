echo off

call ../scripts/set-DOCKER_FOLDER.bat

set LOCAL_FOLDER=%DOCKER_FOLDER%\immich\_data

REM Open the code folder in Windows Explorer
explorer %LOCAL_FOLDER%
