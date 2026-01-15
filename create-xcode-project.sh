#!/bin/bash

# Script pentru a crea Xcode project clasic pentru Mr.V Agent

echo "🚀 Creating Xcode Project for Mr.V Agent..."
echo ""

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}📝 Instrucțiuni:${NC}"
echo ""
echo "1. Deschide Xcode (dacă nu e deschis deja)"
echo "2. File → New → Project"
echo "3. Selectează: macOS → App"
echo "4. Completează:"
echo "   - Product Name: MrVAgent"
echo "   - Team: (Alege Apple ID-ul tău)"
echo "   - Organization Identifier: com.vict0r"
echo "   - Interface: SwiftUI"
echo "   - Language: Swift"
echo "5. Salvează în: $(pwd)/XcodeProject"
echo ""
echo -e "${GREEN}Apasă Enter când ai terminat pasii de mai sus...${NC}"
read

# Create directory structure
mkdir -p XcodeProject
cd XcodeProject

echo ""
echo "✅ Gata! Acum:"
echo ""
echo "6. În Xcode Project Navigator, ȘTERGE fișierele default:"
echo "   - ContentView.swift"
echo "   - MrVAgentApp.swift (dacă există)"
echo ""
echo "7. Deschide Finder la: $(dirname $(pwd))/MrVAgent/"
echo ""
echo "8. Drag & drop TOATE fișierele în Xcode:"
echo "   - Models/"
echo "   - Services/"
echo "   - ViewModels/"
echo "   - Views/"
echo "   - Assets.xcassets/"
echo "   - MrVAgentApp.swift"
echo ""
echo "9. În dialog, bifează:"
echo "   ✅ Copy items if needed"
echo "   ✅ Create groups"
echo "   ✅ Add to targets: MrVAgent"
echo ""
echo "10. Click pe MrVAgent (iconița albastră sus)"
echo "11. Tab 'Signing & Capabilities'"
echo "12. Click '+ Capability' → Adaugă 'Keychain Sharing'"
echo ""
echo "13. Build & Run (Cmd+R)"
echo ""
echo -e "${GREEN}🎉 Enjoy Mr.V Agent!${NC}"
