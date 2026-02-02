import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../../../core/utils/extensions.dart';
import '../providers/channel_pack_provider.dart';
import '../widgets/apk_selector.dart';
import '../widgets/channel_selector.dart';
import '../widgets/pack_progress_card.dart';
import '../widgets/walle_status_banner.dart';
import 'dart:io';

/// 渠道打包页面
class ChannelPackPage extends HookConsumerWidget {
  const ChannelPackPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final apkPath = useState<String?>(null);
    final selectedChannels = useState<List<String>>([]);
    final outputDir = useState<String>('/tmp/mason_output');

    final packState = ref.watch(packStateProvider);
    final packNotifier = ref.read(packNotifierProvider);

    final canStartPack = apkPath.value != null &&
        selectedChannels.value.isNotEmpty &&
        packState is PackStateIdle;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mason - 渠道打包工具'),
        actions: [
          IconButton(
            onPressed: () => _showAboutDialog(context),
            icon: const Icon(Icons.info_outline),
            tooltip: '关于',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Walle 状态横幅
                const WalleStatusBanner(),

                const SizedBox(height: 24),

                // APK 选择器
                ApkSelector(
                  apkPath: apkPath.value,
                  onPathChanged: (path) => apkPath.value = path,
                ),

                const SizedBox(height: 24),

                // 渠道选择器
                ChannelSelector(
                  selectedChannels: selectedChannels.value,
                  onChanged: (channels) =>
                      selectedChannels.value = channels,
                ),

                const SizedBox(height: 24),

                // 输出目录选择
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '输出目录',
                          style: context.textTheme.titleLarge,
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: TextEditingController(
                                  text: outputDir.value,
                                )..selection = TextSelection.fromPosition(
                                    TextPosition(offset: outputDir.value.length)),
                                decoration: const InputDecoration(
                                  hintText: '请选择输出目录',
                                  border: OutlineInputBorder(),
                                ),
                                onChanged: (value) =>
                                    outputDir.value = value,
                              ),
                            ),
                            const SizedBox(width: 12),
                            OutlinedButton(
                              onPressed: () => _selectOutputDir(outputDir),
                              child: const Text('选择'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // 进度卡片
                PackProgressCard(state: packState),

                const SizedBox(height: 24),

                // 操作按钮
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: canStartPack
                            ? () => _startPack(
                                  packNotifier,
                                  apkPath.value!,
                                  outputDir.value,
                                  selectedChannels.value,
                                )
                            : null,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text('开始打包'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    if (packState is! PackStateIdle)
                      OutlinedButton(
                        onPressed: () => packNotifier.reset(),
                        child: const Text('重置'),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _selectOutputDir(ValueNotifier<String> outputDir) async {
    // 这里可以集成 directory_picker
    // 暂时使用默认值
    outputDir.value = '/tmp/mason_output_${DateTime.now().millisecondsSinceEpoch}';
  }

  void _startPack(
    dynamic packNotifier,
    String apkPath,
    String outputDir,
    List<String> channels,
  ) async {
    // 验证输出目录
    final dir = Directory(outputDir);
    if (!dir.existsSync()) {
      await dir.create(recursive: true);
    }

    await packNotifier.startPack(
      apkPath: apkPath,
      outputDir: outputDir,
      channels: channels,
    );
  }

  void _showAboutDialog(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'Mason',
      applicationVersion: '1.0.0',
      applicationIcon: const Icon(Icons.android, size: 48),
      children: [
        const Text('基于 Walle 的跨平台渠道打包工具'),
        const SizedBox(height: 8),
        const Text('支持 macOS 和 Windows'),
      ],
    );
  }
}
