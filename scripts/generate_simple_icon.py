#!/usr/bin/env python3
"""
生成 Mason 应用的简洁几何图标
使用 CoreGraphics 或直接生成 PNG
"""

try:
    from PIL import Image, ImageDraw
    HAS_PIL = True
except ImportError:
    HAS_PIL = False

import os

def create_simple_icon(size):
    """创建简洁的 M 字母几何图标"""
    # 如果没有 PIL，使用 ASCII art 或者安装提示
    if not HAS_PIL:
        print("错误: 需要安装 Pillow 库")
        print("请运行: pip3 install Pillow")
        return None

    # 背景 - 深色
    bg_color = (13, 17, 23)
    # 前景 - 霓虹青
    fg_color = (0, 245, 255)

    img = Image.new('RGBA', (size, size), bg_color + (255,))
    draw = ImageDraw.Draw(img)

    # 计算参数
    padding = size // 6
    draw_size = size - 2 * padding
    stroke_width = max(size // 12, 2)

    # 绘制简洁的 M 字母 - 几何风格
    # M 的两个外竖线
    left_x = padding
    right_x = size - padding
    top_y = padding
    bottom_y = size - padding
    mid_y = size // 2

    # 绘制 M 形状
    points = [
        (left_x, top_y),           # 左上
        (left_x, bottom_y),        # 左下
        (size // 2, mid_y),        # 中间顶点
        (right_x, bottom_y),       # 右下
        (right_x, top_y),          # 右上
    ]

    # 绘制连接线
    for i in range(len(points) - 1):
        draw.line([points[i], points[i + 1]], fill=fg_color, width=stroke_width)

    return img

def main():
    if not HAS_PIL:
        print("正在安装 Pillow...")
        os.system("pip3 install Pillow -q")
        # 重新导入
        try:
            from PIL import Image, ImageDraw
        except ImportError:
            print("无法安装 Pillow，请手动安装: pip3 install Pillow")
            return

    SIZES = [16, 32, 64, 128, 256, 512, 1024]

    # 输出目录
    output_dir = "/Users/taicheng/dev/source/taicheng/flutter/mason/mason/macos/Runner/Assets.xcassets/AppIcon.appiconset"
    os.makedirs(output_dir, exist_ok=True)

    # 生成各尺寸图标
    for size in SIZES:
        icon = create_simple_icon(size)
        if icon:
            output_path = os.path.join(output_dir, f'app_icon_{size}.png')
            icon.save(output_path)
            print(f'Generated: app_icon_{size}.png')

    # 生成 iconset 用于 icns
    iconset_dir = "/Users/taicheng/dev/source/taicheng/flutter/mason/mason/macos/Runner/Resources/AppIcon.iconset"
    os.makedirs(iconset_dir, exist_ok=True)

    # macOS iconset 格式
    icon_mappings = [
        ("16", "icon_16x16.png"),
        ("32", "icon_16x16@2x.png"),
        ("32", "icon_32x32.png"),
        ("64", "icon_32x32@2x.png"),
        ("128", "icon_128x128.png"),
        ("256", "icon_128x128@2x.png"),
        ("256", "icon_256x256.png"),
        ("512", "icon_256x256@2x.png"),
        ("512", "icon_512x512.png"),
        ("1024", "icon_512x512@2x.png"),
    ]

    for size_name, output_name in icon_mappings:
        size = int(size_name)
        icon = create_simple_icon(size)
        if icon:
            output_path = os.path.join(iconset_dir, output_name)
            icon.save(output_path)

    # 使用 iconutil 生成 icns
    icns_path = "/Users/taicheng/dev/source/taicheng/flutter/mason/mason/macos/Runner/Resources/AppIcon.icns"
    os.system(f"rm -f {icns_path}")
    os.system(f"iconutil -c icns {iconset_dir} -o {icns_path}")

    print(f'\n✓ 图标生成完成!')
    print(f'  PNG: {output_dir}')
    print(f'  ICNS: {icns_path}')

if __name__ == '__main__':
    main()
