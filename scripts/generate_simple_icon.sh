#!/bin/bash
# 使用 ImageMagick 生成简洁的 Mason 应用图标

SIZES=(16 32 64 128 256 512 1024)
OUTPUT_DIR="macos/Runner/Assets.xcassets/AppIcon.appiconset"
ICONSET_DIR="macos/Runner/Resources/AppIcon.iconset"

# 颜色
BG_COLOR="#0D1117"
FG_COLOR="#00F5FF"

for SIZE in "${SIZES[@]}"; do
    # 计算参数
    PADDING=$((SIZE / 6))
    STROKE_WIDTH=$((SIZE / 12))
    if [ $STROKE_WIDTH -lt 2 ]; then
        STROKE_WIDTH=2
    fi

    LEFT_X=$PADDING
    RIGHT_X=$((SIZE - PADDING))
    TOP_Y=$PADDING
    BOTTOM_Y=$((SIZE - PADDING))
    MID_Y=$((SIZE / 2))

    # 创建背景
    convert -size ${SIZE}x${SIZE} "xc:$BG_COLOR" "temp_bg_${SIZE}.png"

    # 绘制 M 形状的线条
    # 左竖线
    convert "temp_bg_${SIZE}.png" \
        -fill "$FG_COLOR" \
        -draw "stroke-width $STROKE_WIDTH stroke '$FG_COLOR' line $LEFT_X,$TOP_Y $LEFT_X,$BOTTOM_Y" \
        "temp_bg_${SIZE}.png"

    # 左斜线到中间
    convert "temp_bg_${SIZE}.png" \
        -fill "$FG_COLOR" \
        -draw "stroke-width $STROKE_WIDTH stroke '$FG_COLOR' line $LEFT_X,$BOTTOM_Y $MID_Y,$MID_Y" \
        "temp_bg_${SIZE}.png"

    # 右斜线从中间
    convert "temp_bg_${SIZE}.png" \
        -fill "$FG_COLOR" \
        -draw "stroke-width $STROKE_WIDTH stroke '$FG_COLOR' line $MID_Y,$MID_Y $RIGHT_X,$BOTTOM_Y" \
        "temp_bg_${SIZE}.png"

    # 右竖线
    convert "temp_bg_${SIZE}.png" \
        -fill "$FG_COLOR" \
        -draw "stroke-width $STROKE_WIDTH stroke '$FG_COLOR' line $RIGHT_X,$BOTTOM_Y $RIGHT_X,$TOP_Y" \
        "temp_bg_${SIZE}.png"

    # 保存图标
    mv "temp_bg_${SIZE}.png" "$OUTPUT_DIR/app_icon_${SIZE}.png"
    echo "Generated: app_icon_${SIZE}.png"
done

# 生成 iconset 用于 icns
mkdir -p "$ICONSET_DIR"

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
iconutil -c icns "$ICONSET_DIR" -o "macos/Runner/Resources/AppIcon.icns" 2>/dev/null || echo "iconutil 失败，将在 Xcode 构建时生成"

echo ""
echo "✓ 图标生成完成!"
