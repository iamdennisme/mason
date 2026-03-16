# Mason (Rust + Iced)

Mason 是一个跨平台 Android 渠道打包桌面工具（macOS / Linux / Windows）。

## 技术栈

- UI: `iced`（Rust-native 渲染）
- Core: `Rust`
- 渠道写入: `walle-cli-all.jar`
- Java: 三端均使用**内置 JRE**（不回退系统 Java）
- 字体: 内置 `HarmonyOS Sans SC`（修复中文乱码）

## 功能

- 选择 APK 文件
- 选择输出目录
- 导入渠道列表文件（不限制后缀）/手动增删/清空
- 批量执行 `java -jar walle-cli-all.jar put`
- 实时进度与日志

## 国际化

- 仅界面文案国际化（中文/英文）
- 启动时自动检测系统语言：`zh* -> 中文`，其他 -> 英文
- 日志与错误输出保持原始文本，不做翻译

## 本地开发

不依赖系统 Java 的本地运行：

```bash
./scripts/run_local.sh
```

该脚本会：
- 编译 release 二进制
- 从 Adoptium API 下载 JRE 17
- 注入运行时目录（macOS: `target/Resources`，Linux: `target/release/resources`）
- 拷贝 `walle-cli-all.jar`
- 启动应用

仅下载 JRE 到指定目录：

```bash
./scripts/download_jre.sh target/Resources/jre
```

Windows：

```powershell
.\scripts\download_jre.ps1 -OutDir "target\release\resources\jre"
```

## 运行时资源路径

- macOS: `Mason.app/Contents/Resources/jre/bin/java`
- Linux: `<exe_dir>/resources/jre/bin/java`
- Windows: `<exe_dir>/resources/jre/bin/java.exe`
- Walle: `<resources>/walle/walle-cli-all.jar`

## 发布构建（GitHub Actions）

工作流：`.github/workflows/rust-release.yml`

触发：推送 tag（例如 `v1.0.0`）

说明：CI 会在构建时直接下载 JRE（Adoptium），并打入各平台产物，不依赖 Runner 系统 Java。

产物：

- macOS: `dmg`
- Linux: `AppImage + deb`
- Windows: `NSIS installer + portable zip`
