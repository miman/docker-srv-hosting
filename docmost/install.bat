@echo off
REM Docmost Docker install script for Windows

REM Create docmost directory if it doesn't exist
if not exist docmost mkdir docmost
cd docmost

REM Download the docker-compose.yml file if it doesn't exist
if not exist docker-compose.yml curl -O https://raw.githubusercontent.com/docmost/docmost/main/docker-compose.yml

REM Change the hosting port from 3000 to 4412 in the compose file
if exist docker-compose.yml powershell -Command "(Get-Content docker-compose.yml) -replace '- \"3000:3000\"', '- 4412:3000' | Set-Content docker-compose.yml"

REM Generate a random UUID (at least 32 chars) for APP_SECRET and replace in the compose file
for /f %%i in ('powershell -Command "[guid]::NewGuid().ToString('N') + [guid]::NewGuid().ToString('N').Substring(0, 16)"') do set APP_SECRET=%%i
echo Generated APP_SECRET: %APP_SECRET%
if exist docker-compose.yml powershell -Command "(Get-Content docker-compose.yml) -replace 'REPLACE_WITH_LONG_SECRET', '%APP_SECRET%' | Set-Content docker-compose.yml"

REM Prompt user to edit docker-compose.yml for secrets and passwords
echo Please edit the docker-compose.yml file to set:
echo - APP_URL (your domain or http://localhost:4412)
echo - STRONG_DB_PASSWORD (replace in POSTGRES_PASSWORD and DATABASE_URL)
echo Press any key to continue after you have finished editing...
pause >nul

REM Start the services
docker compose up -d

cd ..

echo Docmost is now running. Open http://localhost:4412 or your configured domain to complete setup.
echo You App Secret is: %APP_SECRET%

