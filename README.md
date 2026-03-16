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

本地打包 macOS `.dmg`（内置 JRE）：

```bash
./scripts/package_macos_dmg.sh
```

会同时生成安装指引文件：`dist/MACOS_INSTALL.md`。

常用参数：

```bash
./scripts/package_macos_dmg.sh --version 1.0.0
./scripts/package_macos_dmg.sh --skip-jre-download
./scripts/package_macos_dmg.sh --skip-build
```

性能说明（窗口缩放）：
- 调试模式 `cargo run` 在 UI 重排时会更慢，缩放体验不代表最终发布效果。
- 建议用 `cargo build --release && ./target/release/mason` 验证桌面流畅度。
- 应用日志默认仅保留最近 300 条，界面默认渲染最近 120 条以降低重排开销。

## 运行时资源路径

- macOS: `Mason.app/Contents/Resources/jre/bin/java`
- Linux: `<exe_dir>/resources/jre/bin/java`
- Windows: `<exe_dir>/resources/jre/bin/java.exe`
- Walle: `<resources>/walle/walle-cli-all.jar`

## 图标资源

- 主设计源：`resources/icons/mason-master.svg`
- 导出产物：`mason-master-1024.png`、`mason.png`、`mason.icns`、`mason.ico`
- 重新生成：

```bash
./scripts/generate_icons.sh
```

## 发布构建（GitHub Actions）

工作流：`.github/workflows/rust-release.yml`

触发：推送 tag（例如 `v1.0.0`）

说明：CI 会在构建时直接下载 JRE（Adoptium），并打入各平台产物，不依赖 Runner 系统 Java。

macOS 发布说明（当前无 Apple Developer 账号）：
- macOS 产物为 **Apple Silicon (arm64) only**
- 当前不含 Developer ID 签名与公证（notarization）
- 首次启动若被 Gatekeeper 拦截：在 `Applications` 里右键 `Mason.app` -> `打开` -> 再次 `打开`
- 备用命令：`xattr -dr com.apple.quarantine /Applications/Mason.app`

产物：

- macOS: `dmg` + `MACOS_INSTALL.md`
- Linux: `AppImage + deb`
- Windows: `NSIS installer + portable zip`
