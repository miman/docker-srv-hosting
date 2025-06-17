echo off

call ../scripts/set-DOCKER_FOLDER.bat

set LOCAL_FOLDER=%DOCKER_FOLDER%\traccar_traccar_data\_data

REM Open the code folder in Windows Explorer
explorer %LOCAL_FOLDER%
