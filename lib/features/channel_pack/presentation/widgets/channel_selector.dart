import 'package:flutter/material.dart';
import '../../../../core/constants/app_constants.dart';
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
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: ChannelInfo.defaultChannels.map((channel) {
                final isSelected = _selectedChannels.contains(channel);
                return FilterChip(
                  label: Text(channel),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedChannels.add(channel);
                      } else {
                        _selectedChannels.remove(channel);
                      }
                    });
                    widget.onChanged(_selectedChannels.toList());
                  },
                  selectedColor: AppColors.primary.withValues(alpha: 0.2),
                  checkmarkColor: AppColors.primary,
                  backgroundColor: AppColors.surfaceVariant,
                  side: BorderSide(
                    color: isSelected
                        ? AppColors.primary
                        : AppColors.border,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _selectAll,
                    icon: const Icon(Icons.select_all, size: 18),
                    label: const Text('全选'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _clearAll,
                    icon: const Icon(Icons.clear, size: 18),
                    label: const Text('清空'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _selectAll() {
    setState(() {
      _selectedChannels = ChannelInfo.defaultChannels.toSet();
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
