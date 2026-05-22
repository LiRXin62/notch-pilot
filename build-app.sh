#!/bin/bash
set -e

PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
APP_NAME="NotchPilot"
APP_DIR="$PROJECT_DIR/$APP_NAME.app"

echo "Building release binary..."
swift build -c release

echo "Creating .app bundle..."
rm -rf "$APP_DIR"
mkdir -p "$APP_DIR/Contents/MacOS" "$APP_DIR/Contents/Resources"

cp "$PROJECT_DIR/.build/release/$APP_NAME" "$APP_DIR/Contents/MacOS/"
cp "$PROJECT_DIR/Info.plist" "$APP_DIR/Contents/"

echo "Done: $APP_DIR"
echo ""
echo "To run:  open '$APP_DIR'"
echo "To install:  cp -r '$APP_DIR' /Applications/"
