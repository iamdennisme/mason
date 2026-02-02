#!/bin/bash
# 使用源图标生成各种尺寸的应用图标

SOURCE_ICON="/Users/taicheng/Downloads/Gemini_Generated_Image_koxlrckoxlrckoxl.png"
OUTPUT_DIR="macos/Runner/Assets.xcassets/AppIcon.appiconset"
ICONSET_DIR="macos/Runner/Resources/AppIcon.iconset"

SIZES=(16 32 64 128 256 512 1024)

echo "从源图标生成各尺寸图标..."

for SIZE in "${SIZES[@]}"; do
    magick "$SOURCE_ICON" -resize ${SIZE}x${SIZE} "$OUTPUT_DIR/app_icon_${SIZE}.png"
    echo "Generated: app_icon_${SIZE}.png"
done

# 生成 iconset
cp "$OUTPUT_DIR/app_icon_16.png" "$ICONSET_DIR/icon_16x16.png"
cp "$OUTPUT_DIR/app_icon_32.png" "$ICONSET_DIR/icon_16x16@2x.png"
cp "$OUTPUT_DIR/app_icon_32.png" "$ICONSET_DIR/icon_32x32.png"
cp "$OUTPUT_DIR/app_icon_64.png" "$ICONSET_DIR/icon_32x32@2x.png"
cp "$OUTPUT_DIR/app_icon_128.png" "$ICONSET_DIR/icon_128x128.png"
cp "$OUTPUT_DIR/app_icon_256.png" "$ICONSET_DIR/icon_128x128@2x.png"
cp "$OUTPUT_DIR/app_icon_256.png" "$ICONSET_DIR/icon_256x256.png"
cp "$OUTPUT_DIR/app_icon_512.png" "$ICONSET_DIR/icon_256x256@2x.png"
cp "$OUTPUT_DIR/app_icon_512.png" "$ICONSET_DIR/icon_512x512.png"
cp "$OUTPUT_DIR/app_icon_1024.png" "$ICONSET_DIR/icon_512x512@2x.png"

# 生成 ICNS
rm -f "macos/Runner/Resources/AppIcon.icns"
iconutil -c icns "$ICONSET_DIR" -o "macos/Runner/Resources/AppIcon.icns" 2>/dev/null

echo ""
echo "✓ 图标生成完成!"
ls -la "macos/Runner/Resources/AppIcon.icns"
