#!/bin/bash
# 从 SVG 生成高质量图标（修复白色背景问题）

SVG_FILE="/Users/taicheng/dev/source/taicheng/flutter/mason/mason/scripts/mason_icon.svg"
OUTPUT_DIR="/Users/taicheng/dev/source/taicheng/flutter/mason/mason/macos/Runner/Assets.xcassets/AppIcon.appiconset"
ICONSET_DIR="/Users/taicheng/dev/source/taicheng/flutter/mason/mason/macos/Runner/Resources/AppIcon.iconset"

SIZES=(16 32 64 128 256 512 1024)

echo "从 SVG 生成高质量图标..."

for SIZE in "${SIZES[@]}"; do
    # 使用 rsvg-convert 渲染（如果可用），否则用 ImageMagick
    if command -v rsvg-convert &> /dev/null; then
        rsvg-convert -w $SIZE -h $SIZE -o "$OUTPUT_DIR/app_icon_${SIZE}.png" "$SVG_FILE"
    else
        # ImageMagick with proper transparency handling
        magick "$SVG_FILE" \
            -resize ${SIZE}x${SIZE} \
            -define png:exclude-chunk=bkgd \
            -define png:color-type=6 \
            "$OUTPUT_DIR/app_icon_${SIZE}.png"
    fi
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
rm -f "/Users/taicheng/dev/source/taicheng/flutter/mason/mason/macos/Runner/Resources/AppIcon.icns"
iconutil -c icns "$ICONSET_DIR" -o "/Users/taicheng/dev/source/taicheng/flutter/mason/mason/macos/Runner/Resources/AppIcon.icns" 2>/dev/null

echo "✓ 图标生成完成!"
