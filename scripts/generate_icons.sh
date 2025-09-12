#!/bin/bash

echo "Generating Neon Pulse App Icons..."
echo "=================================="

# Check if Python is installed
if ! command -v python3 &> /dev/null; then
    echo "Error: Python 3 is not installed"
    echo "Please install Python 3 from https://python.org"
    exit 1
fi

# Check if pip is available
if ! command -v pip3 &> /dev/null; then
    echo "Error: pip3 is not available"
    echo "Please install pip3"
    exit 1
fi

# Check if Pillow is installed
python3 -c "import PIL" 2>/dev/null
if [ $? -ne 0 ]; then
    echo "Installing Pillow..."
    pip3 install Pillow
    if [ $? -ne 0 ]; then
        echo "Error: Failed to install Pillow"
        exit 1
    fi
fi

# Run the icon generation script
echo "Running icon generation..."
python3 generate_icons.py

if [ $? -ne 0 ]; then
    echo "Error: Icon generation failed"
    exit 1
fi

echo ""
echo "✅ Icons generated successfully!"
echo ""
echo "Next steps:"
echo "1. Clean and rebuild your Flutter project"
echo "2. Test the app on device to verify icons appear correctly"
echo ""