import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/extensions.dart';
import '../providers/channel_pack_provider.dart' as provider;

/// Walle 状态横幅
class WalleStatusBanner extends ConsumerWidget {
  const WalleStatusBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusAsync = ref.watch(provider.walleStatusProvider);

    return statusAsync.when(
      data: (status) {
        if (status.isInstalled) {
          return const SizedBox.shrink();
        }

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.warning.withValues(alpha: 0.1),
            border: const Border(
              left: BorderSide(color: AppColors.warning, width: 4),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.warning_amber,
                    color: AppColors.warning,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Walle 未安装',
                    style: context.textTheme.titleMedium?.copyWith(
                      color: AppColors.warning,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '请下载 Walle JAR 文件并放置到以下位置:',
                style: context.textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  status.path ?? '未知路径',
                  style: context.textTheme.bodySmall?.copyWith(
                    fontFamily: 'monospace',
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: () => _openDownloadUrl(context),
                    icon: const Icon(Icons.download, size: 18),
                    label: const Text('下载 Walle'),
                  ),
                  const SizedBox(width: 12),
                  TextButton.icon(
                    onPressed: () =>
                        _openFolder(context, status.path ?? '未知路径'),
                    icon: const Icon(Icons.folder_open, size: 18),
                    label: const Text('打开文件夹'),
                  ),
                ],
              ),
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (error, stackTrace) => const SizedBox.shrink(),
    );
  }

  void _openDownloadUrl(BuildContext context) {
    // 在实际应用中，可以使用 url_launcher 打开链接
    context.showSnackBar(
      '请访问以下地址下载:\n${AppConstants.walleDownloadUrl}',
    );
  }

  void _openFolder(BuildContext context, String path) {
    context.showSnackBar('请手动打开文件夹: $path');
    // 在桌面平台可以使用 Process.run 打开文件夹
  }
}
