#!/bin/bash

# Mr.V Agent - Open in Xcode Script
# This script opens the project directly in Xcode

echo "🚀 Opening Mr.V Agent in Xcode..."
echo ""

# Check if Xcode is installed
if ! command -v xcodebuild &> /dev/null; then
    echo "❌ Error: Xcode is not installed or not in PATH"
    echo "Please install Xcode from the Mac App Store"
    exit 1
fi

# Get the script's directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Check if Package.swift exists
if [ ! -f "$SCRIPT_DIR/Package.swift" ]; then
    echo "❌ Error: Package.swift not found"
    exit 1
fi

# Open in Xcode
open "$SCRIPT_DIR/Package.swift"

echo "✅ Xcode should open shortly..."
echo ""
echo "📝 Next steps:"
echo "  1. Wait for Xcode to load the project"
echo "  2. Select 'My Mac' as the device"
echo "  3. Click Run (▶️) or press Cmd+R"
echo "  4. Set your password (first time only)"
echo "  5. Configure API keys in Settings"
echo ""
echo "🎉 Enjoy Mr.V Agent!"
