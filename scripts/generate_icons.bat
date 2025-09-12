@echo off
echo Generating Neon Pulse App Icons...
echo =====================================

REM Check if Python is installed
python --version >nul 2>&1
if errorlevel 1 (
    echo Error: Python is not installed or not in PATH
    echo Please install Python from https://python.org
    pause
    exit /b 1
)

REM Check if Pillow is installed
python -c "import PIL" >nul 2>&1
if errorlevel 1 (
    echo Installing Pillow...
    pip install Pillow
    if errorlevel 1 (
        echo Error: Failed to install Pillow
        pause
        exit /b 1
    )
)

REM Run the icon generation script
echo Running icon generation...
python generate_icons.py

if errorlevel 1 (
    echo Error: Icon generation failed
    pause
    exit /b 1
)

echo.
echo ✅ Icons generated successfully!
echo.
echo Next steps:
echo 1. Clean and rebuild your Flutter project
echo 2. Test the app on device to verify icons appear correctly
echo.
pause