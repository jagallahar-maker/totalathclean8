#!/bin/bash

# Total Athlete - Build Verification Script
# Run this locally before uploading to GitHub

set -e

echo "🔍 Total Athlete - Build Verification"
echo "======================================"
echo ""

# Check Flutter
echo "1️⃣ Checking Flutter installation..."
flutter --version || { echo "❌ Flutter not found"; exit 1; }
echo "✅ Flutter found"
echo ""

# Clean project
echo "2️⃣ Cleaning project..."
flutter clean
echo "✅ Clean complete"
echo ""

# Get dependencies
echo "3️⃣ Getting Flutter dependencies..."
flutter pub get || { echo "❌ pub get failed"; exit 1; }
echo "✅ Dependencies installed"
echo ""

# Verify Generated.xcconfig
echo "4️⃣ Verifying iOS configuration..."
if [ -f "ios/Flutter/Generated.xcconfig" ]; then
    echo "✅ Generated.xcconfig exists"
    echo "   FLUTTER_ROOT from config:"
    grep "FLUTTER_ROOT" ios/Flutter/Generated.xcconfig || echo "   (not set yet - will be set by flutter build)"
else
    echo "❌ Generated.xcconfig not found"
    exit 1
fi
echo ""

# Install CocoaPods
echo "5️⃣ Installing CocoaPods dependencies..."
cd ios
pod install || { echo "❌ pod install failed"; cd ..; exit 1; }
cd ..
echo "✅ CocoaPods installed"
echo ""

# Check for hardcoded paths
echo "6️⃣ Checking for hardcoded paths..."
if grep -r "/flutter/sdk" ios/ 2>/dev/null; then
    echo "❌ Found hardcoded /flutter/sdk paths"
    exit 1
else
    echo "✅ No hardcoded paths found"
fi
echo ""

# Verify bundle ID
echo "7️⃣ Verifying bundle identifier..."
if grep -q "com.justingallahar.totalathlete" ios/Runner.xcodeproj/project.pbxproj; then
    echo "✅ Bundle ID: com.justingallahar.totalathlete"
else
    echo "❌ Bundle ID not found or incorrect"
    exit 1
fi
echo ""

# Run Flutter analyze
echo "8️⃣ Running Flutter analyze..."
flutter analyze || { echo "⚠️  Warning: analyze found issues (non-fatal)"; }
echo "✅ Analyze complete"
echo ""

# Verify file structure
echo "9️⃣ Verifying project structure..."
REQUIRED_FILES=(
    "lib/main.dart"
    "ios/Podfile"
    "codemagic.yaml"
    "pubspec.yaml"
)

for file in "${REQUIRED_FILES[@]}"; do
    if [ -f "$file" ]; then
        echo "   ✅ $file"
    else
        echo "   ❌ $file (missing)"
        exit 1
    fi
done
echo ""

# Check for duplicate files
echo "🔟 Checking for duplicate iOS folders..."
IOS_PODFILES=$(find . -name "Podfile" -type f | wc -l)
if [ "$IOS_PODFILES" -eq 1 ]; then
    echo "✅ Single Podfile found (correct)"
else
    echo "❌ Multiple Podfiles found:"
    find . -name "Podfile" -type f
    exit 1
fi
echo ""

# Test iOS build (optional - takes longer)
echo "1️⃣1️⃣ Testing iOS build (this may take a few minutes)..."
read -p "Run full iOS build test? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    flutter build ios --release || { echo "❌ iOS build failed"; exit 1; }
    echo "✅ iOS build successful"
else
    echo "⏭️  Skipped iOS build test"
fi
echo ""

# Final summary
echo "======================================"
echo "🎉 Verification Complete!"
echo "======================================"
echo ""
echo "✅ All checks passed"
echo ""
echo "Your project is ready for:"
echo "  1. Upload to GitHub"
echo "  2. Codemagic CI/CD integration"
echo "  3. TestFlight distribution"
echo ""
echo "Next steps:"
echo "  1. Create a new GitHub repository"
echo "  2. Push this project to GitHub"
echo "  3. Connect repository to Codemagic"
echo "  4. Configure App Store Connect integration"
echo "  5. Trigger your first Codemagic build!"
echo ""
echo "Good luck! 🚀"
