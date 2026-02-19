#!/bin/bash

# Source files
IC_LAUNCHER="/Users/hts-mac243/Downloads/zbzzar/android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png"
SPLASH_IMAGE="/Users/hts-mac243/Downloads/zbzzar/android/app/src/main/res/drawable/splash_image.png"

# Destination directories
APP_ICON_DIR="/Users/hts-mac243/Downloads/zbzzar/ios/Runner/Assets.xcassets/AppIcon.appiconset"
LAUNCH_IMAGE_DIR="/Users/hts-mac243/Downloads/zbzzar/ios/Runner/Assets.xcassets/LaunchImage.imageset"

# Create directories if they don't exist (should exist already)
mkdir -p "$APP_ICON_DIR"
mkdir -p "$LAUNCH_IMAGE_DIR"

# Generate App Icons
echo "Generating App Icons..."
sips -z 40 40 "$IC_LAUNCHER" --out "$APP_ICON_DIR/Icon-App-20x20@2x.png"
sips -z 60 60 "$IC_LAUNCHER" --out "$APP_ICON_DIR/Icon-App-20x20@3x.png"
sips -z 29 29 "$IC_LAUNCHER" --out "$APP_ICON_DIR/Icon-App-29x29@1x.png"
sips -z 58 58 "$IC_LAUNCHER" --out "$APP_ICON_DIR/Icon-App-29x29@2x.png"
sips -z 87 87 "$IC_LAUNCHER" --out "$APP_ICON_DIR/Icon-App-29x29@3x.png"
sips -z 40 40 "$IC_LAUNCHER" --out "$APP_ICON_DIR/Icon-App-40x40@1x.png"
sips -z 80 80 "$IC_LAUNCHER" --out "$APP_ICON_DIR/Icon-App-40x40@2x.png"
sips -z 120 120 "$IC_LAUNCHER" --out "$APP_ICON_DIR/Icon-App-40x40@3x.png"
sips -z 50 50 "$IC_LAUNCHER" --out "$APP_ICON_DIR/Icon-App-50x50@1x.png"
sips -z 100 100 "$IC_LAUNCHER" --out "$APP_ICON_DIR/Icon-App-50x50@2x.png"
sips -z 57 57 "$IC_LAUNCHER" --out "$APP_ICON_DIR/Icon-App-57x57@1x.png"
sips -z 114 114 "$IC_LAUNCHER" --out "$APP_ICON_DIR/Icon-App-57x57@2x.png"
sips -z 120 120 "$IC_LAUNCHER" --out "$APP_ICON_DIR/Icon-App-60x60@2x.png"
sips -z 180 180 "$IC_LAUNCHER" --out "$APP_ICON_DIR/Icon-App-60x60@3x.png"
sips -z 72 72 "$IC_LAUNCHER" --out "$APP_ICON_DIR/Icon-App-72x72@1x.png"
sips -z 144 144 "$IC_LAUNCHER" --out "$APP_ICON_DIR/Icon-App-72x72@2x.png"
sips -z 76 76 "$IC_LAUNCHER" --out "$APP_ICON_DIR/Icon-App-76x76@1x.png"
sips -z 152 152 "$IC_LAUNCHER" --out "$APP_ICON_DIR/Icon-App-76x76@2x.png"
sips -z 167 167 "$IC_LAUNCHER" --out "$APP_ICON_DIR/Icon-App-83.5x83.5@2x.png"
sips -z 1024 1024 "$IC_LAUNCHER" --out "$APP_ICON_DIR/Icon-App-1024x1024@1x.png"

# Generate Launch Images
echo "Generating Launch Images..."
# 1x
cp "$SPLASH_IMAGE" "$LAUNCH_IMAGE_DIR/LaunchImage.png"
# 2x
sips -z 288 288 "$SPLASH_IMAGE" --out "$LAUNCH_IMAGE_DIR/LaunchImage@2x.png"
# 3x
sips -z 432 432 "$SPLASH_IMAGE" --out "$LAUNCH_IMAGE_DIR/LaunchImage@3x.png"

echo "Done."
