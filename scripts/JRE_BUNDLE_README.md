# JRE 打包配置说明

## 概述

项目已配置为在打包时只包含对应平台的 JRE：

- **macOS**: `jre/macos/jre/` → 复制到 `.app/Contents/Resources/jre/`
- **Windows**: `jre/windows/jre/` → 复制到可执行文件旁边的 `jre/` 目录

## macOS 配置

### 已完成的配置

1. **Xcode Build Phase**: `scripts/setup_macos_jre.rb` 已自动添加 "Copy JRE" 构建阶段
2. **复制脚本**: `scripts/copy_jre_macos.sh` 会在构建时复制 JRE

### 构建 macOS 应用

```bash
# 方法 1: 直接使用 Flutter
flutter build macos

# 方法 2: 使用 Xcode（调试）
open macos/Runner.xcworkspace
# 然后在 Xcode 中运行 (Cmd+R)
```

## Windows 配置

### 已完成的配置

`windows/CMakeLists.txt` 已添加 JRE 安装步骤，JRE 会在构建时自动复制到可执行文件旁边。

### 构建 Windows 应用

```bash
flutter build windows
```

构建后的目录结构：
```
build/windows/runner/Release/
├── mason.exe
├── jre/
│   └── bin/
│       └── java.exe
└── ...其他文件
```

## 重新运行配置脚本

如果需要重新配置 Xcode 构建阶段：

```bash
ruby scripts/setup_macos_jre.rb
```

## JRE 位置

- **macOS JRE 源**: `jre/macos/jre/Contents/Home/bin/java`
- **Windows JRE 源**: `jre/windows/jre/bin/java.exe`

这些 JRE 已预提取，无需从 assets 解压。
