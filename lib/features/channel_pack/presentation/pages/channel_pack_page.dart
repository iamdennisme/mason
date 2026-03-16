import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:window_manager/window_manager.dart';
import 'dart:io';
import 'package:mason/core/theme/app_colors.dart';
import 'package:mason/core/theme/app_theme.dart';
import 'package:mason/core/utils/java_manager.dart';
import '../providers/channel_pack_provider.dart';

/// Mason 渠道打包工具 - 极简专业风格
class ChannelPackPage extends HookConsumerWidget {
  const ChannelPackPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final apkPath = useState<String?>(null);
    final selectedChannels = useState<List<String>>([]);
    final outputDir = useState<String?>(null);  // 改为可空，需要用户选择
    final packOutput = useState<List<PackLog>>([]);

    final packState = ref.watch(packStateProvider);
    final lastState = useRef<PackState?>(null);

    // 页面加载时检查 JRE
    useEffect(() {
      () async {
        try {
          final java = await JavaManager.instance.getJavaExecutable();
          debugPrint('✓ JRE 已找到: ${java.path}');
        } catch (e) {
          debugPrint('✗ JRE 查找失败: $e');
        }
      }();
      return null;
    }, []);

    // 监听打包状态变化（去重）
    useEffect(() {
      // 只在状态真正变化时添加日志
      if (lastState.value == packState) return;

      packState.when(
        idle: () => null,
        packing: (currentChannel, current, total, progress) {
          // 如果从非 packing 状态变为 packing，添加开始日志
          if (lastState.value is! PackStatePacking) {
            packOutput.value = [
              ...packOutput.value,
              PackLog.info('开始打包 $total 个渠道'),
              PackLog.blank(),
            ];
          }
          // 每次渠道变化时，添加一条新的进度日志（不替换之前的）
          if (currentChannel.isNotEmpty) {
            // 检查是否已经记录过这个渠道
            final lastLog = packOutput.value.isNotEmpty
                ? packOutput.value.last
                : null;
            final alreadyLogged = lastLog != null &&
                lastLog.type == PackLogType.progress &&
                lastLog.text.contains(currentChannel);

            if (!alreadyLogged) {
              packOutput.value = [
                ...packOutput.value,
                PackLog.progress('正在打包: $currentChannel ($current/$total)'),
              ];
            }
          }
        },
        completed: (generatedFiles, duration) {
          packOutput.value = [
            ...packOutput.value,
            PackLog.blank(),
            PackLog.success('打包完成! 生成了 ${generatedFiles.length} 个渠道包'),
          ];
        },
        failed: (error) {
          packOutput.value = [
            ...packOutput.value,
            PackLog.blank(),
            PackLog.error(error),
          ];
        },
      );

      lastState.value = packState;
      return null;
    }, [packState]);

    final canStartPack = apkPath.value != null &&
        outputDir.value != null &&
        selectedChannels.value.isNotEmpty &&
        packState is PackStateIdle;

    return Material(
      color: AppColors.background,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Column(
          children: [
            // 自定义标题栏（沉浸式）
            _CustomTitleBar(),

            // 主内容区域
            Expanded(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1000),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(40),
                    child: Column(
                      children: [
                        // 标题
                        _Header(),

                        const SizedBox(height: 32),

                        // 左右两列布局
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 左列：APK + 渠道列表
                            Expanded(
                              flex: 1,
                              child: _LeftColumn(
                                apkPath: apkPath.value,
                                outputDir: outputDir.value,
                                selectedChannels: selectedChannels.value,
                                isDisabled: packState is PackStatePacking,
                                onApkSelected: () => _selectApk(apkPath),
                                onOutputDirChanged: () => _selectOutputDir(outputDir),
                                onChannelsChanged: (channels) =>
                                    selectedChannels.value = channels,
                              ),
                            ),

                            const SizedBox(width: 24),

                            // 右列：日志面板 + 开始打包按钮
                            Expanded(
                              flex: 1,
                              child: Column(
                                children: [
                                  _LogPanel(
                                    logs: packOutput.value,
                                    onClear: () => packOutput.value = [],
                                  ),
                                  const SizedBox(height: 16),
                                  _MainActionButton(
                                    label: packState is PackStatePacking ? '打包中...' : '开始打包',
                                    isActive: canStartPack,
                                    isPacking: packState is PackStatePacking,
                                    onPressed: canStartPack ? () => _startPack(
                                      ref,
                                      apkPath.value!,
                                      selectedChannels.value,
                                      outputDir.value,
                                      packOutput,
                                    ) : null,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectApk(ValueNotifier<String?> apkPath) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['apk'],
    );
    if (result != null && result.files.isNotEmpty) {
      apkPath.value = result.files.single.path;
    }
  }

  Future<void> _selectOutputDir(ValueNotifier<String?> outputDir) async {
    final result = await FilePicker.platform.getDirectoryPath();
    if (result != null) {
      outputDir.value = result;
    }
  }

  void _startPack(
    WidgetRef ref,
    String apkPath,
    List<String> channels,
    String? outputDir,
    ValueNotifier<List<PackLog>> output,
  ) {
    output.value = [
      PackLog.info('APK: ${apkPath.split('/').last}'),
      PackLog.info('渠道数: ${channels.length}'),
      PackLog.blank(),
    ];

    ref.read(packNotifierProvider).startPack(
      apkPath: apkPath,
      channels: channels,
      outputDir: outputDir,
    );
  }
}

/// 打包日志条目
class PackLog {
  final String text;
  final PackLogType type;

  const PackLog({
    required this.text,
    this.type = PackLogType.normal,
  });

  factory PackLog.success(String text) =>
      PackLog(text: text, type: PackLogType.success);
  factory PackLog.error(String text) =>
      PackLog(text: text, type: PackLogType.error);
  factory PackLog.info(String text) =>
      PackLog(text: text, type: PackLogType.info);
  factory PackLog.progress(String text) =>
      PackLog(text: text, type: PackLogType.progress);
  factory PackLog.blank() =>
      const PackLog(text: '', type: PackLogType.blank);
}

enum PackLogType {
  normal,
  success,
  error,
  info,
  progress,
  blank,
}

/// 自定义标题栏（支持拖动和窗口控制）
class _CustomTitleBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
          bottom: BorderSide(
            color: AppColors.border,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // 窗口控制按钮（macOS 在左侧）
          if (Platform.isMacOS) _MacOSWindowControls(),

          // 拖动区域（占满整个标题栏）
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onPanStart: (_) {
                windowManager.startDragging();
              },
              child: const SizedBox.expand(),
            ),
          ),

          // 窗口控制按钮（Windows 在右侧）
          if (Platform.isWindows) _WindowsWindowControls(),
        ],
      ),
    );
  }
}

/// macOS 风格窗口控制按钮（红绿黄）
class _MacOSWindowControls extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const SizedBox(width: 12),
        _MacOSControlButton(
          color: const Color(0xFFFF5F57),
          icon: Icons.close,
          onPressed: () async => await windowManager.close(),
        ),
        const SizedBox(width: 8),
        _MacOSControlButton(
          color: const Color(0xFFFEBC2E),
          icon: Icons.horizontal_rule,
          onPressed: () async => await windowManager.minimize(),
        ),
        const SizedBox(width: 8),
        _MacOSControlButton(
          color: const Color(0xFF28C840),
          icon: Icons.crop_square,
          onPressed: () async {
            final isMaximized = await windowManager.isMaximized();
            if (isMaximized) {
              await windowManager.unmaximize();
            } else {
              await windowManager.maximize();
            }
          },
        ),
        const SizedBox(width: 12),
      ],
    );
  }
}

/// macOS 风格控制按钮
class _MacOSControlButton extends StatefulWidget {
  final Color color;
  final IconData icon;
  final VoidCallback onPressed;

  const _MacOSControlButton({
    required this.color,
    required this.icon,
    required this.onPressed,
  });

  @override
  State<_MacOSControlButton> createState() => _MacOSControlButtonState();
}

class _MacOSControlButtonState extends State<_MacOSControlButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onPressed,
        child: Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: widget.color,
            shape: BoxShape.circle,
          ),
          child: _isHovered
              ? Icon(
                  widget.icon,
                  size: 8,
                  color: Colors.black54,
                )
              : null,
        ),
      ),
    );
  }
}

/// Windows 风格窗口控制按钮
class _WindowsWindowControls extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _WindowsControlButton(
          icon: Icons.horizontal_rule,
          onPressed: () async => await windowManager.minimize(),
        ),
        _WindowsControlButton(
          icon: Icons.crop_square,
          onPressed: () async {
            final isMaximized = await windowManager.isMaximized();
            if (isMaximized) {
              await windowManager.unmaximize();
            } else {
              await windowManager.maximize();
            }
          },
        ),
        _WindowsControlButton(
          icon: Icons.close,
          isClose: true,
          onPressed: () async => await windowManager.close(),
        ),
      ],
    );
  }
}

/// Windows 风格控制按钮
class _WindowsControlButton extends StatefulWidget {
  final IconData icon;
  final bool isClose;
  final VoidCallback onPressed;

  const _WindowsControlButton({
    required this.icon,
    this.isClose = false,
    required this.onPressed,
  });

  @override
  State<_WindowsControlButton> createState() => _WindowsControlButtonState();
}

class _WindowsControlButtonState extends State<_WindowsControlButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onPressed,
        child: Container(
          width: 46,
          height: 40,
          color: _isHovered
              ? (widget.isClose ? const Color(0xFFE81123) : AppColors.surfaceVariant)
              : Colors.transparent,
          child: Icon(
            widget.icon,
            size: 16,
            color: _isHovered ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

/// 标题
class _Header extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            Icons.widgets_outlined,
            color: AppColors.primary,
            size: 24,
          ),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Mason',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
                letterSpacing: -0.5,
              ),
            ),
            Text(
              'Android 渠道打包工具',
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// 左列：APK + 渠道列表
class _LeftColumn extends StatelessWidget {
  const _LeftColumn({
    required this.apkPath,
    required this.outputDir,
    required this.selectedChannels,
    required this.isDisabled,
    required this.onApkSelected,
    required this.onOutputDirChanged,
    required this.onChannelsChanged,
  });

  final String? apkPath;
  final String? outputDir;
  final List<String> selectedChannels;
  final bool isDisabled;
  final VoidCallback onApkSelected;
  final VoidCallback onOutputDirChanged;
  final ValueChanged<List<String>> onChannelsChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // APK 选择
        _ApkSelector(
          apkPath: apkPath,
          isDisabled: isDisabled,
          onTap: onApkSelected,
        ),

        const SizedBox(height: 16),

        // 输出目录
        _OutputSelector(
          outputDir: outputDir,
          isDisabled: isDisabled,
          onTap: onOutputDirChanged,
        ),

        const SizedBox(height: 16),

        // 渠道列表（压缩高度）
        _ChannelSection(
          channels: selectedChannels,
          isDisabled: isDisabled,
          onChannelsChanged: onChannelsChanged,
        ),
      ],
    );
  }
}

/// APK 选择器
class _ApkSelector extends StatelessWidget {
  const _ApkSelector({
    required this.apkPath,
    required this.isDisabled,
    required this.onTap,
  });

  final String? apkPath;
  final bool isDisabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fileName = apkPath?.split('/').last;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.border,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标签
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Text(
              'APK 文件',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textTertiary,
              ),
            ),
          ),

          // 内容
          Row(
            children: [
              // 图标
              Container(
                width: 40,
                height: 40,
                margin: const EdgeInsets.only(left: 12, bottom: 12),
                decoration: BoxDecoration(
                  color: apkPath != null
                      ? AppColors.success.withValues(alpha: 0.1)
                      : AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  apkPath != null ? Icons.check : Icons.android,
                  color: apkPath != null ? AppColors.success : AppColors.textTertiary,
                  size: 18,
                ),
              ),

              // 文件名
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: 12, bottom: 12),
                  child: fileName != null
                      ? Text(
                          fileName,
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        )
                      : Text(
                          '选择 APK 文件',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.textTertiary,
                          ),
                        ),
                ),
              ),

              // 选择按钮
              _CompactButton(
                label: '选择',
                isActive: !isDisabled,
                onTap: onTap,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// 输出目录选择器
class _OutputSelector extends StatelessWidget {
  const _OutputSelector({
    required this.outputDir,
    required this.isDisabled,
    required this.onTap,
  });

  final String? outputDir;
  final bool isDisabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final displayPath = outputDir ?? '请选择输出目录';

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.border,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标签
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Text(
              '输出目录',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textTertiary,
              ),
            ),
          ),

          // 内容
          Row(
            children: [
              // 图标
              Container(
                width: 40,
                height: 40,
                margin: const EdgeInsets.only(left: 12, bottom: 12),
                decoration: BoxDecoration(
                  color: outputDir != null
                      ? AppColors.success.withValues(alpha: 0.1)
                      : AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  outputDir != null ? Icons.check : Icons.folder_outlined,
                  color: outputDir != null ? AppColors.success : AppColors.textSecondary,
                  size: 18,
                ),
              ),

              // 路径
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: 12, bottom: 12),
                  child: Text(
                    displayPath,
                    style: TextStyle(
                      fontSize: 14,
                      color: outputDir != null ? AppColors.textPrimary : AppColors.textTertiary,
                      fontFamily: AppTheme.monospaceFontFamily,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),

              // 选择/更改按钮
              _CompactButton(
                label: outputDir != null ? '更改' : '选择',
                isActive: !isDisabled,
                onTap: onTap,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// 紧凑按钮
class _CompactButton extends StatefulWidget {
  const _CompactButton({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  final String label;
  final bool isActive;
  final VoidCallback? onTap;

  @override
  State<_CompactButton> createState() => _CompactButtonState();
}

class _CompactButtonState extends State<_CompactButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: widget.isActive ? SystemMouseCursors.click : SystemMouseCursors.basic,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.isActive ? widget.onTap : null,
        child: Container(
          width: 60,
          height: 40,
          margin: const EdgeInsets.only(right: 12, bottom: 12),
          decoration: BoxDecoration(
            color: _isHovered && widget.isActive
                ? AppColors.primary.withValues(alpha: 0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              widget.label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: widget.isActive
                    ? (_isHovered ? AppColors.primary : AppColors.textSecondary)
                    : AppColors.textTertiary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 主操作按钮
class _MainActionButton extends StatefulWidget {
  const _MainActionButton({
    required this.label,
    required this.isActive,
    required this.isPacking,
    required this.onPressed,
  });

  final String label;
  final bool isActive;
  final bool isPacking;
  final VoidCallback? onPressed;

  @override
  State<_MainActionButton> createState() => _MainActionButtonState();
}

class _MainActionButtonState extends State<_MainActionButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.isActive ? widget.onPressed : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        height: 48,
        decoration: BoxDecoration(
          color: widget.isActive
              ? (_isPressed
                  ? AppColors.primary.withValues(alpha: 0.8)
                  : AppColors.primary)
              : AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: widget.isPacking
              ? _PulsingIndicator()
              : Text(
                  widget.label,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: widget.isActive ? Colors.white : AppColors.textTertiary,
                  ),
                ),
        ),
      ),
    );
  }
}

/// 脉冲加载指示器
class _PulsingIndicator extends StatefulWidget {
  @override
  State<_PulsingIndicator> createState() => _PulsingIndicatorState();
}

class _PulsingIndicatorState extends State<_PulsingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(3, (index) {
            return Container(
              width: 8,
              height: 8,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(
                  alpha: _animation.value * (1 - index * 0.2),
                ),
                shape: BoxShape.circle,
              ),
            );
          }),
        );
      },
    );
  }
}

/// 渠道管理区域（可折叠）
class _ChannelSection extends StatefulWidget {
  const _ChannelSection({
    required this.channels,
    required this.isDisabled,
    required this.onChannelsChanged,
  });

  final List<String> channels;
  final bool isDisabled;
  final ValueChanged<List<String>> onChannelsChanged;

  @override
  State<_ChannelSection> createState() => _ChannelSectionState();
}

class _ChannelSectionState extends State<_ChannelSection> {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.border,
          width: 1,
        ),
      ),
      child: Column(
        children: [
          // 标题栏（固定，不可折叠）
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: AppColors.border,
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.list_alt,
                  size: 18,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 10),
                Text(
                  '渠道列表',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${widget.channels.length}',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                const Spacer(),
                if (!widget.isDisabled) ...[
                  _IconTextButton(
                    icon: Icons.upload_file,
                    label: '导入',
                    onPressed: () => _importChannels(),
                  ),
                  const SizedBox(width: 4),
                  _IconTextButton(
                    icon: Icons.clear_all,
                    label: '清空',
                    onPressed: () => _clearChannels(),
                  ),
                ],
              ],
            ),
          ),

          // 内容（渠道列表 + 添加栏始终显示）
          _ChannelList(
            channels: widget.channels,
            isDisabled: widget.isDisabled,
            onChanged: widget.onChannelsChanged,
          ),
        ],
      ),
    );
  }

  Future<void> _importChannels() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['txt', 'text'],
    );
    if (result != null && result.files.isNotEmpty) {
      final file = result.files.single;
      final content = await file.xFile.readAsString();
      final newChannels = content
          .split(RegExp(r'[\r\n]+'))
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();

      // 合并现有渠道和新导入的渠道，去重
      final mergedChannels = {...widget.channels, ...newChannels}.toList();
      widget.onChannelsChanged(mergedChannels);
    }
  }

  void _clearChannels() {
    widget.onChannelsChanged([]);
  }
}

/// 渠道列表（限制高度，可滚动）
class _ChannelList extends StatefulWidget {
  const _ChannelList({
    required this.channels,
    required this.isDisabled,
    required this.onChanged,
  });

  final List<String> channels;
  final bool isDisabled;
  final ValueChanged<List<String>> onChanged;

  @override
  State<_ChannelList> createState() => _ChannelListState();
}

class _ChannelListState extends State<_ChannelList> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _addChannel(String name) {
    if (name.isNotEmpty) {
      widget.onChanged([...widget.channels, name]);
    }
  }

  void _removeChannel(String channel) {
    widget.onChanged(widget.channels.where((c) => c != channel).toList());
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 渠道列表（固定高度，常驻显示）
        SizedBox(
          height: 140,
          child: widget.channels.isEmpty
              ? Center(
                  child: Text(
                    '暂无渠道',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textTertiary,
                    ),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: widget.channels.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 4),
                  itemBuilder: (context, index) {
                    final channel = widget.channels[index];
                    return _ChannelItem(
                      channel: channel,
                      index: index,
                      isDisabled: widget.isDisabled,
                      onRemove: () => _removeChannel(channel),
                    );
                  },
                ),
        ),

        // 添加栏（常驻显示）
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(
                color: AppColors.border,
                width: 1,
              ),
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.add,
                size: 18,
                color: AppColors.textTertiary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _controller,
                  enabled: !widget.isDisabled,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textPrimary,
                  ),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: '添加新渠道...',
                    hintStyle: TextStyle(
                      fontSize: 14,
                      color: AppColors.textTertiary,
                    ),
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                  onSubmitted: _addChannel,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// 单个渠道项
class _ChannelItem extends StatefulWidget {
  const _ChannelItem({
    required this.channel,
    required this.index,
    required this.isDisabled,
    required this.onRemove,
  });

  final String channel;
  final int index;
  final bool isDisabled;
  final VoidCallback onRemove;

  @override
  State<_ChannelItem> createState() => _ChannelItemState();
}

class _ChannelItemState extends State<_ChannelItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 20,
              child: Text(
                '${widget.index + 1}',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textTertiary,
                  fontFamily: AppTheme.monospaceFontFamily,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                widget.channel,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            if (!widget.isDisabled && _isHovered)
              InkWell(
                onTap: widget.onRemove,
                borderRadius: BorderRadius.circular(4),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  child: Icon(
                    Icons.close,
                    size: 16,
                    color: AppColors.textTertiary,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// 日志面板（始终显示）
class _LogPanel extends StatelessWidget {
  const _LogPanel({
    required this.logs,
    required this.onClear,
  });

  final List<PackLog> logs;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 280, // 固定压缩高度
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.border,
          width: 1,
        ),
      ),
      child: Column(
        children: [
          // 标题栏
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: AppColors.border,
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.terminal_outlined,
                  size: 16,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 8),
                Text(
                  '打包日志',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${logs.length}',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.textTertiary,
                    ),
                  ),
                ),
                const Spacer(),
                _CompactTextButton(
                  label: '清空',
                  onTap: onClear,
                ),
              ],
            ),
          ),

          // 日志内容（始终展开）
          Expanded(
            child: logs.isEmpty
                ? Center(
                    child: Text(
                      '暂无日志',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textTertiary,
                      ),
                    ),
                  )
                : Padding(
                    padding: const EdgeInsets.all(16),
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: logs.map((log) => _LogItem(log: log)).toList(),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

/// 日志条目
class _LogItem extends StatelessWidget {
  const _LogItem({required this.log});

  final PackLog log;

  @override
  Widget build(BuildContext context) {
    if (log.type == PackLogType.blank) {
      return const SizedBox(height: 4);
    }

    final color = _getColor(log.type);

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '•',
            style: TextStyle(
              fontSize: 12,
              color: color,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              log.text,
              style: TextStyle(
                fontSize: 13,
                fontFamily: AppTheme.monospaceFontFamily,
                color: color,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getColor(PackLogType type) {
    switch (type) {
      case PackLogType.success:
        return AppColors.success;
      case PackLogType.error:
        return AppColors.error;
      case PackLogType.info:
        return AppColors.textSecondary;
      case PackLogType.progress:
        return AppColors.primary;
      default:
        return AppColors.textSecondary;
    }
  }
}

/// 紧凑文本按钮
class _CompactTextButton extends StatefulWidget {
  const _CompactTextButton({
    required this.label,
    required this.onTap,
  });

  final String label;
  final VoidCallback onTap;

  @override
  State<_CompactTextButton> createState() => _CompactTextButtonState();
}

class _CompactTextButtonState extends State<_CompactTextButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: _isHovered ? AppColors.surfaceVariant : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            widget.label,
            style: TextStyle(
              fontSize: 12,
              color: _isHovered ? AppColors.primary : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

/// 图标文字按钮
class _IconTextButton extends StatefulWidget {
  const _IconTextButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  State<_IconTextButton> createState() => _IconTextButtonState();
}

class _IconTextButtonState extends State<_IconTextButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onPressed,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: _isHovered ? AppColors.surfaceVariant : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                widget.icon,
                size: 14,
                color: _isHovered ? AppColors.primary : AppColors.textSecondary,
              ),
              const SizedBox(width: 4),
              Text(
                widget.label,
                style: TextStyle(
                  fontSize: 12,
                  color: _isHovered ? AppColors.primary : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
