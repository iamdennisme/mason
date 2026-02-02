#!/usr/bin/env python3
"""
生成 Mason 应用的砖石风格图标
"""

from PIL import Image, ImageDraw
import os

# 图标尺寸
SIZES = [16, 32, 64, 128, 256, 512, 1024]

# 颜色
BG_COLOR = (13, 17, 23)  # #0D1117 深色背景
BRICK_COLOR = (0, 245, 255)  # #00F5FF 霓虹青

def create_brick_icon(size):
    """创建指定尺寸的砖石图标"""
    img = Image.new('RGBA', (size, size), BG_COLOR + (255,))
    draw = ImageDraw.Draw(img)

    # 计算砖块大小和数量
    if size <= 32:
        brick_rows = 2
        brick_cols = 2
        padding = size // 8
    elif size <= 64:
        brick_rows = 3
        brick_cols = 3
        padding = size // 10
    elif size <= 128:
        brick_rows = 4
        brick_cols = 4
        padding = size // 12
    else:
        brick_rows = 5
        brick_cols = 5
        padding = size // 15

    # 计算砖块尺寸
    total_padding = padding * (brick_cols + 1)
    brick_size = (size - total_padding) // max(brick_rows, brick_cols)

    # 绘制砖块图案（交错排列）
    for row in range(brick_rows):
        for col in range(brick_cols):
            # 交错效果：奇数行偏移
            offset = 0 if row % 2 == 0 else brick_size // 2 + padding // 2

            x = padding + col * (brick_size + padding) + offset
            y = padding + row * (brick_size + padding)

            # 确保不超出边界
            if x + brick_size <= size - padding:
                # 绘制圆角矩形砖块
                corner_radius = brick_size // 4
                draw.rounded_rectangle(
                    [x, y, x + brick_size, y + brick_size],
                    radius=corner_radius,
                    fill=BRICK_COLOR + (255,)
                )

    return img

def main():
    # 输出目录
    output_dir = os.path.join(os.path.dirname(__file__), '..', 'macos', 'Runner', 'Assets.xcassets', 'AppIcon.appiconset')
    os.makedirs(output_dir, exist_ok=True)

    # 生成各尺寸图标
    for size in SIZES:
        icon = create_brick_icon(size)
        output_path = os.path.join(output_dir, f'app_icon_{size}.png')
        icon.save(output_path)
        print(f'Generated: app_icon_{size}.png')

    print(f'\nIcons generated successfully in {output_dir}')

if __name__ == '__main__':
    main()
