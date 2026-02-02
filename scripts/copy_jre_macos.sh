#!/bin/bash
# macOS JRE 复制脚本
# 在 Xcode Build Phase 中调用此脚本
# Usage: scripts/copy_jre_macos.sh

set -e

# 获取构建产品路径
BUILT_PRODUCTS_DIR="${BUILT_PRODUCTS_DIR:-}"
CONTENTS_FOLDER_PATH="${CONTENTS_FOLDER_PATH:-}"

if [ -z "$BUILT_PRODUCTS_DIR" ] || [ -z "$CONTENTS_FOLDER_PATH" ]; then
    echo "错误: 此脚本需要从 Xcode Build Phase 运行"
    echo "或者设置环境变量: BUILT_PRODUCTS_DIR 和 CONTENTS_FOLDER_PATH"
    exit 1
fi

# 源 JRE 路径（项目根目录）
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
JRE_SOURCE="$PROJECT_DIR/jre/macos/jre"

# 目标路径（app bundle 内的 Resources）
JRE_DEST="$BUILT_PRODUCTS_DIR/$CONTENTS_FOLDER_PATH/Resources/jre"

echo "Copying JRE from: $JRE_SOURCE"
echo "Copying JRE to: $JRE_DEST"

# 复制 JRE
if [ -d "$JRE_SOURCE" ]; then
    rm -rf "$JRE_DEST"
    cp -R "$JRE_SOURCE" "$JRE_DEST"
    echo "JRE copied successfully"
else
    echo "警告: JRE 源目录不存在: $JRE_SOURCE"
fi
