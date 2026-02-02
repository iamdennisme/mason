#!/bin/bash
# 使用 ImageMagick 生成 Mason 应用图标

SIZES=(16 32 64 128 256 512 1024)
OUTPUT_DIR="macos/Runner/Assets.xcassets/AppIcon.appiconset"

# 颜色
BG_COLOR="#0D1117"
BRICK_COLOR="#00F5FF"

for SIZE in "${SIZES[@]}"; do
    # 计算参数
    if [ $SIZE -le 32 ]; then
        ROWS=2
        COLS=2
        PADDING=$((SIZE / 8))
    elif [ $SIZE -le 64 ]; then
        ROWS=3
        COLS=3
        PADDING=$((SIZE / 10))
    elif [ $SIZE -le 128 ]; then
        ROWS=4
        COLS=4
        PADDING=$((SIZE / 12))
    else
        ROWS=5
        COLS=5
        PADDING=$((SIZE / 15))
    fi

    # 计算砖块大小
    TOTAL_PADDING=$((PADDING * (COLS + 1)))
    BRICK_SIZE=$(( (SIZE - TOTAL_PADDING) / COLS))

    # 创建背景
    convert -size ${SIZE}x${SIZE} "xc:$BG_COLOR" "temp_bg_${SIZE}.png"

    # 绘制砖块（交错排列）
    ROW=0
    while [ $ROW -lt $ROWS ]; do
        COL=0
        OFFSET=0
        if [ $((ROW % 2)) -eq 1 ]; then
            OFFSET=$((BRICK_SIZE / 2 + PADDING / 2))
        fi

        while [ $COL -lt $COLS ]; do
            X=$((PADDING + COL * (BRICK_SIZE + PADDING) + OFFSET))
            Y=$((PADDING + ROW * (BRICK_SIZE + PADDING)))
            RADIUS=$((BRICK_SIZE / 4))

            if [ $((X + BRICK_SIZE)) -le $((SIZE - PADDING)) ]; then
                # 绘制圆角矩形
                convert "temp_bg_${SIZE}.png" \
                    -fill "$BRICK_COLOR" \
                    -draw "roundrectangle $X,$Y $((X + BRICK_SIZE)),$((Y + BRICK_SIZE)) $RADIUS,$RADIUS" \
                    "temp_bg_${SIZE}.png"
            fi

            COL=$((COL + 1))
        done
        ROW=$((ROW + 1))
    done

    # 保存图标
    mv "temp_bg_${SIZE}.png" "$OUTPUT_DIR/app_icon_${SIZE}.png"
    echo "Generated: app_icon_${SIZE}.png"
done

echo ""
echo "Icons generated successfully!"
