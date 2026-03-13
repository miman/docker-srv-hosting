@echo off
REM Installing ComfyUI into a Docker container

REM Stop any running ComfyUI container
echo Stopping existing ComfyUI container if it exists...
docker compose down

REM Build the Docker image (the Dockerfile clones the repo)
echo Building ComfyUI Docker image...
docker compose build

REM Start the ComfyUI container in detached mode
echo Starting ComfyUI Docker container...
docker compose up -d

echo ComfyUI has been installed and is accessible on http://localhost:4515

REM Prompt the user if they want to download models
set /p downloadModels=Do you want to download models for ComfyUI ? (Y/N): 

IF /i "%downloadModels%" EQU "Y" (
    echo Models will be downloaded...
    call download-models.bat
) ELSE (
    echo No models will be downloaded.
)

echo Find the model ranking here:  https://imgsys.org
echo Find & download them here:  https://civitai.com/models
