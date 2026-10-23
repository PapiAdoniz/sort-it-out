#!/bin/bash
# Build a drag-to-Applications disk image for Sort It Out.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
APP="${1:-"$ROOT/build/DerivedData/Build/Products/Release/Sort It Out.app"}"
DIST="$ROOT/dist"
STAGING="$DIST/staging"
VERSION="1.3.1"
RW_DMG="$DIST/Sort.It.Out-${VERSION}-rw.dmg"
DMG="$DIST/Sort.It.Out-${VERSION}.dmg"
VOLUME="Sort It Out"
BG_DIR="$STAGING/.background"

if [[ ! -d "$APP" ]]; then
  echo "App not found at: $APP" >&2
  exit 1
fi

rm -rf "$STAGING"
mkdir -p "$DIST" "$BG_DIR"
rm -f "$RW_DMG" "$DMG"

swift - "$BG_DIR/background.png" <<'SWIFT'
import AppKit
import Foundation

let width = 660
let height = 400
let output = CommandLine.arguments[1]
let image = NSImage(size: NSSize(width: width, height: height))
image.lockFocus()

NSColor(calibratedRed: 0.075, green: 0.082, blue: 0.098, alpha: 1).setFill()
NSRect(x: 0, y: 0, width: width, height: height).fill()

if let glow = NSGradient(colors: [
    NSColor(calibratedRed: 0.16, green: 0.20, blue: 0.26, alpha: 1),
    NSColor(calibratedRed: 0.075, green: 0.082, blue: 0.098, alpha: 1)
]) {
    glow.draw(in: NSRect(x: 0, y: 0, width: width, height: height), relativeCenterPosition: NSPoint(x: 0, y: 0.05))
}

let title = "Sort It Out" as NSString
let titleFont = NSFont(name: "Avenir Next Medium", size: 32) ?? NSFont.systemFont(ofSize: 32, weight: .medium)
let titleAttrs: [NSAttributedString.Key: Any] = [
    .font: titleFont,
    .foregroundColor: NSColor(calibratedWhite: 0.96, alpha: 1)
]
let titleSize = title.size(withAttributes: titleAttrs)
title.draw(at: NSPoint(x: (CGFloat(width) - titleSize.width) / 2, y: CGFloat(height) - 78), withAttributes: titleAttrs)

let subtitle = "Version 1.3.1  ·  Drag the app to Applications" as NSString
let subtitleAttrs: [NSAttributedString.Key: Any] = [
    .font: NSFont(name: "Avenir Next", size: 14) ?? NSFont.systemFont(ofSize: 14),
    .foregroundColor: NSColor(calibratedWhite: 0.72, alpha: 1)
]
let subtitleSize = subtitle.size(withAttributes: subtitleAttrs)
subtitle.draw(at: NSPoint(x: (CGFloat(width) - subtitleSize.width) / 2, y: 36), withAttributes: subtitleAttrs)

image.unlockFocus()

guard let tiff = image.tiffRepresentation,
      let rep = NSBitmapImageRep(data: tiff),
      let png = rep.representation(using: .png, properties: [:]) else {
    fputs("Could not render the disk image background.\n", stderr)
    exit(1)
}
try png.write(to: URL(fileURLWithPath: output))
SWIFT

ditto "$APP" "$STAGING/Sort It Out.app"
ln -s /Applications "$STAGING/Applications"

ICON_SRC="$ROOT/FSO/Assets.xcassets/AppIcon.appiconset/icon_512x512.png"
if [[ -f "$ICON_SRC" ]]; then
  ICONSET="$STAGING/VolumeIcon.iconset"
  mkdir -p "$ICONSET"
  for SIZE in 16 32 128 256 512; do
    sips -z "$SIZE" "$SIZE" "$ICON_SRC" --out "$ICONSET/icon_${SIZE}x${SIZE}.png" >/dev/null
    DOUBLE=$((SIZE * 2))
    sips -z "$DOUBLE" "$DOUBLE" "$ICON_SRC" --out "$ICONSET/icon_${SIZE}x${SIZE}@2x.png" >/dev/null
  done
  iconutil -c icns "$ICONSET" -o "$STAGING/.VolumeIcon.icns"
  rm -rf "$ICONSET"
fi

hdiutil create -volname "$VOLUME" -srcfolder "$STAGING" -ov -format UDRW -fs HFS+ "$RW_DMG" >/dev/null
MOUNT="$(hdiutil attach -readwrite -noverify -noautoopen "$RW_DMG" | awk '/\/Volumes\// {print substr($0, index($0, "/Volumes/"))}')"

if [[ -f "$MOUNT/.VolumeIcon.icns" ]]; then
  chflags hidden "$MOUNT/.VolumeIcon.icns" || true
  if command -v SetFile >/dev/null 2>&1; then
    SetFile -a C "$MOUNT" || true
  fi
fi
chflags hidden "$MOUNT/.background" || true

osascript <<APPLESCRIPT
tell application "Finder"
  tell disk "$VOLUME"
    open
    set current view of container window to icon view
    set toolbar visible of container window to false
    set statusbar visible of container window to false
    set the bounds of container window to {240, 120, 900, 520}
    set theViewOptions to the icon view options of container window
    set arrangement of theViewOptions to not arranged
    set icon size of theViewOptions to 128
    set background picture of theViewOptions to file ".background:background.png"
    set position of item "Sort It Out.app" of container window to {140, 155}
    set position of item "Applications" of container window to {420, 155}
    close
    open
    update without registering applications
    delay 1
    close
  end tell
end tell
APPLESCRIPT

sync
hdiutil detach "$MOUNT" >/dev/null
hdiutil convert "$RW_DMG" -format UDZO -imagekey zlib-level=9 -o "$DMG" >/dev/null
rm -f "$RW_DMG"
rm -rf "$STAGING"

echo "Created $DMG"
