import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/extensions.dart';

/// 渠道选择器组件
class ChannelSelector extends StatefulWidget {
  final List<String> selectedChannels;
  final ValueChanged<List<String>> onChanged;

  const ChannelSelector({
    super.key,
    required this.selectedChannels,
    required this.onChanged,
  });

  @override
  State<ChannelSelector> createState() => _ChannelSelectorState();
}

class _ChannelSelectorState extends State<ChannelSelector> {
  late Set<String> _selectedChannels;

  @override
  void initState() {
    super.initState();
    _selectedChannels = widget.selectedChannels.toSet();
  }

  @override
  void didUpdateWidget(ChannelSelector oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedChannels != widget.selectedChannels) {
      _selectedChannels = widget.selectedChannels.toSet();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '选择渠道',
                  style: context.textTheme.titleLarge,
                ),
                Text(
                  '已选 ${_selectedChannels.length} 个',
                  style: context.textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 导入按钮
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _importFromFile,
                    icon: const Icon(Icons.file_upload, size: 18),
                    label: const Text('导入渠道文件'),
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: _selectedChannels.isEmpty ? null : _clearAll,
                  icon: const Icon(Icons.clear, size: 18),
                  label: const Text('清空'),
                ),
              ],
            ),

            // 渠道列表
            if (_selectedChannels.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              Text(
                '渠道列表 (${_selectedChannels.length})',
                style: context.textTheme.titleMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                constraints: const BoxConstraints(maxHeight: 300),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _selectedChannels.length,
                  itemBuilder: (context, index) {
                    final channel = _selectedChannels.elementAt(index);
                    return ListTile(
                      dense: true,
                      leading: Text(
                        '${index + 1}',
                        style: TextStyle(
                          color: AppColors.textTertiary,
                          fontSize: 12,
                        ),
                      ),
                      title: Text(channel),
                      trailing: IconButton(
                        icon: const Icon(Icons.close, size: 18),
                        onPressed: () => _removeChannel(channel),
                        tooltip: '删除',
                        color: AppColors.textSecondary,
                      ),
                    );
                  },
                ),
              ),
            ] else ...[
              const SizedBox(height: 16),
              Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.playlist_add,
                      size: 48,
                      color: AppColors.textTertiary,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '请导入渠道文件',
                      style: TextStyle(
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _importFromFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['txt', 'text'],
      dialogTitle: '选择渠道列表文件',
    );

    if (result != null && result.files.single.path != null) {
      final file = File(result.files.single.path!);
      try {
        final content = await file.readAsString();

        // 按行分割，过滤空行
        final channels = content
            .split(RegExp(r'[\r\n]+'))
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList();

        if (channels.isNotEmpty) {
          setState(() {
            _selectedChannels = channels.toSet();
          });
          widget.onChanged(_selectedChannels.toList());

          if (mounted) {
            context.showSnackBar('成功导入 ${channels.length} 个渠道');
          }
        } else {
          if (mounted) {
            context.showSnackBar('文件中未找到有效渠道');
          }
        }
      } catch (e) {
        if (mounted) {
          context.showSnackBar('导入失败: $e');
        }
      }
    }
  }

  void _removeChannel(String channel) {
    setState(() {
      _selectedChannels.remove(channel);
    });
    widget.onChanged(_selectedChannels.toList());
  }

  void _clearAll() {
    setState(() {
      _selectedChannels = {};
    });
    widget.onChanged([]);
  }
}
