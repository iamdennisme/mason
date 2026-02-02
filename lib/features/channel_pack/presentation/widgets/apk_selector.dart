import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:file_picker/file_picker.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/extensions.dart';

/// APK 文件选择器组件
class ApkSelector extends HookWidget {
  final String? apkPath;
  final ValueChanged<String?> onPathChanged;

  const ApkSelector({
    super.key,
    required this.apkPath,
    required this.onPathChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '选择 APK 文件',
              style: context.textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            InkWell(
              onTap: _selectApkFile,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: apkPath != null
                        ? AppColors.primary
                        : AppColors.border,
                  ),
                  borderRadius: BorderRadius.circular(8),
                  color: apkPath != null
                      ? AppColors.primary.withValues(alpha: 0.05)
                      : Colors.transparent,
                ),
                child: apkPath != null
                    ? _buildFileInfo(context)
                    : _buildDropZone(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropZone(BuildContext context) {
    return Column(
      children: [
        Icon(
          Icons.upload_file,
          size: 48,
          color: AppColors.textSecondary,
        ),
        const SizedBox(height: 12),
        Text(
          '点击选择 APK 文件',
          style: context.textTheme.bodyLarge?.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '支持 .apk 格式',
          style: context.textTheme.bodySmall?.copyWith(
            color: AppColors.textTertiary,
          ),
        ),
      ],
    );
  }

  Widget _buildFileInfo(BuildContext context) {
    final fileName = apkPath!.split('/').last;
    return Row(
      children: [
        Icon(
          Icons.android,
          size: 48,
          color: AppColors.success,
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                fileName,
                style: context.textTheme.bodyLarge,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                '点击更换文件',
                style: context.textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: () => onPathChanged(null),
          icon: const Icon(Icons.close),
          tooltip: '清除',
        ),
      ],
    );
  }

  Future<void> _selectApkFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['apk'],
      dialogTitle: '选择 APK 文件',
    );

    if (result != null && result.files.single.path != null) {
      onPathChanged(result.files.single.path);
    }
  }
}
