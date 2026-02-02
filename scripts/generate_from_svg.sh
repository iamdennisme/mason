#!/bin/bash
# 从 SVG 生成高质量图标（修复白色背景问题）

# 获取脚本所在目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

SVG_FILE="$SCRIPT_DIR/mason_icon.svg"
OUTPUT_DIR="$PROJECT_ROOT/macos/Runner/Assets.xcassets/AppIcon.appiconset"
ICONSET_DIR="$PROJECT_ROOT/macos/Runner/Resources/AppIcon.iconset"
WINDOWS_ICON_DIR="$PROJECT_ROOT/windows/runner/resources"
WINDOWS_ICON="$WINDOWS_ICON_DIR/app_icon.ico"

SIZES=(16 32 64 128 256 512 1024)
WINDOWS_SIZES=(16 32 48 256)

echo "从 SVG 生成高质量图标..."
echo "项目根目录: $PROJECT_ROOT"

# 创建临时目录用于生成 PNG
TEMP_DIR=$(mktemp -d)
trap "rm -rf $TEMP_DIR" EXIT

# 生成各种尺寸的 PNG
for SIZE in "${SIZES[@]}"; do
    # 使用 rsvg-convert 渲染（如果可用），否则用 ImageMagick
    if command -v rsvg-convert &> /dev/null; then
        rsvg-convert -w $SIZE -h $SIZE -o "$TEMP_DIR/app_icon_${SIZE}.png" "$SVG_FILE"
    else
        # ImageMagick with proper transparency handling
        magick "$SVG_FILE" \
            -resize ${SIZE}x${SIZE} \
            -define png:exclude-chunk=bkgd \
            -define png:color-type=6 \
            "$TEMP_DIR/app_icon_${SIZE}.png"
    fi
    echo "Generated: app_icon_${SIZE}.png"
done

# 生成 macOS iconset
echo ""
echo "生成 macOS 图标集..."
mkdir -p "$OUTPUT_DIR"
mkdir -p "$ICONSET_DIR"

cp "$TEMP_DIR/app_icon_16.png" "$ICONSET_DIR/icon_16x16.png"
cp "$TEMP_DIR/app_icon_32.png" "$ICONSET_DIR/icon_16x16@2x.png"
cp "$TEMP_DIR/app_icon_32.png" "$ICONSET_DIR/icon_32x32.png"
cp "$TEMP_DIR/app_icon_64.png" "$ICONSET_DIR/icon_32x32@2x.png"
cp "$TEMP_DIR/app_icon_128.png" "$ICONSET_DIR/icon_128x128.png"
cp "$TEMP_DIR/app_icon_256.png" "$ICONSET_DIR/icon_128x128@2x.png"
cp "$TEMP_DIR/app_icon_256.png" "$ICONSET_DIR/icon_256x256.png"
cp "$TEMP_DIR/app_icon_512.png" "$ICONSET_DIR/icon_256x256@2x.png"
cp "$TEMP_DIR/app_icon_512.png" "$ICONSET_DIR/icon_512x512.png"
cp "$TEMP_DIR/app_icon_1024.png" "$ICONSET_DIR/icon_512x512@2x.png"

# 生成 ICNS
rm -f "$PROJECT_ROOT/macos/Runner/Resources/AppIcon.icns"
iconutil -c icns "$ICONSET_DIR" -o "$PROJECT_ROOT/macos/Runner/Resources/AppIcon.icns" 2>/dev/null

echo "✓ macOS 图标生成完成!"

# 生成 Windows ICO
echo ""
echo "生成 Windows 图标..."
mkdir -p "$WINDOWS_ICON_DIR"

# 使用 ImageMagick 创建多尺寸 ICO 文件
WINDOWS_PNGS=""
for SIZE in "${WINDOWS_SIZES[@]}"; do
    WINDOWS_PNGS="$WINDOWS_PNGS $TEMP_DIR/app_icon_${SIZE}.png"
done

magick $WINDOWS_PNGS "$WINDOWS_ICON"

echo "✓ Windows 图标生成完成: $WINDOWS_ICON"

echo ""
echo "✓ 所有图标生成完成!"
