import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/extensions.dart';
import '../providers/channel_pack_provider.dart' as provider;

/// 环境状态横幅
/// 显示 Java 环境状态，Walle JAR 已打包在应用内
class EnvironmentBanner extends ConsumerWidget {
  const EnvironmentBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final envAsync = ref.watch(provider.environmentProvider);

    return envAsync.when(
      data: (env) {
        if (env.isReady) {
          return const SizedBox.shrink();
        }

        final needsJava = !env.javaInstalled;

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: needsJava
                ? AppColors.warning.withValues(alpha: 0.1)
                : AppColors.success.withValues(alpha: 0.1),
            border: Border(
              left: BorderSide(
                color: needsJava ? AppColors.warning : AppColors.success,
                width: 4,
              ),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    needsJava ? Icons.warning_amber : Icons.check_circle,
                    color: needsJava ? AppColors.warning : AppColors.success,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      needsJava ? '环境准备中...' : '环境就绪',
                      style: context.textTheme.titleMedium?.copyWith(
                        color: needsJava ? AppColors.warning : AppColors.success,
                      ),
                    ),
                  ),
                ],
              ),
              if (needsJava) ...[
                const SizedBox(height: 12),
                Text(
                  '正在初始化 Java 环境，请稍候...',
                  style: context.textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ],
          ),
        );
      },
      loading: () => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.info.withValues(alpha: 0.1),
          border: const Border(
            left: BorderSide(color: AppColors.info, width: 4),
          ),
        ),
        child: const Row(
          children: [
            SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 12),
            Text('检查环境...'),
          ],
        ),
      ),
      error: (error, _) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.1),
          border: const Border(
            left: BorderSide(color: AppColors.error, width: 4),
          ),
        ),
        child: Row(
          children: [
            const Icon(Icons.error, color: AppColors.error),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '环境检查失败: $error',
                style: TextStyle(color: AppColors.error),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
