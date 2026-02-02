#!/bin/bash
# 使用 ImageMagick 生成简洁的 M 字母图标（实心设计）

SIZES=(16 32 64 128 256 512 1024)
OUTPUT_DIR="macos/Runner/Assets.xcassets/AppIcon.appiconset"
ICONSET_DIR="macos/Runner/Resources/AppIcon.iconset"

# 颜色
BG_COLOR="#0D1117"
FG_COLOR="#00F5FF"

for SIZE in "${SIZES[@]}"; do
    # 计算参数
    PADDING=$((SIZE / 8))
    STROKE_WIDTH=$((SIZE / 10))
    if [ $STROKE_WIDTH -lt 2 ]; then
        STROKE_WIDTH=2
    fi

    # 创建背景
    magick -size ${SIZE}x${SIZE} "xc:$BG_COLOR" "temp_${SIZE}.png"

    # 绘制实心 M 形状 - 使用多边形填充
    # M 的坐标点
    LEFT_X=$PADDING
    RIGHT_X=$((SIZE - PADDING))
    TOP_Y=$PADDING
    BOTTOM_Y=$((SIZE - PADDING))
    MID_Y=$((SIZE / 2))
    STEM_WIDTH=$((SIZE / 6))

    # 使用 draw 绘制填充的 M 形状
    magick "temp_${SIZE}.png" \
        -fill "$FG_COLOR" \
        -draw "polygon $LEFT_X,$TOP_Y $((LEFT_X + STEM_WIDTH)),$TOP_Y $((LEFT_X + STEM_WIDTH)),$BOTTOM_Y $MID_Y,$((MID_Y + STEM_WIDTH/2)) $((RIGHT_X - STEM_WIDTH)),$BOTTOM_Y $((RIGHT_X - STEM_WIDTH)),$BOTTOM_Y $((RIGHT_X - STEM_WIDTH)),$TOP_Y $RIGHT_X,$TOP_Y" \
        "temp_${SIZE}.png"

    # 保存到 appiconset
    cp "temp_${SIZE}.png" "$OUTPUT_DIR/app_icon_${SIZE}.png"
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

# 清理临时文件
rm -f temp_*.png

echo ""
echo "✓ M 字母图标生成完成!"
ls -la "macos/Runner/Resources/AppIcon.icns"
