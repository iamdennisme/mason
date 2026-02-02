import 'package:freezed_annotation/freezed_annotation.dart';
import '../../../../core/constants/app_constants.dart';

part 'channel_pack_task.freezed.dart';

/// 渠道打包任务实体
@freezed
sealed class ChannelPackTask with _$ChannelPackTask {
  const factory ChannelPackTask({
    /// 任务 ID
    required String id,

    /// 原始 APK 文件路径
    required String apkPath,

    /// 输出目录
    required String outputDir,

    /// 渠道列表
    required List<String> channels,

    /// 任务状态
    @Default(PackStatus.idle) PackStatus status,

    /// 当前进度 (0.0 - 1.0)
    @Default(0.0) double progress,

    /// 当前正在处理的渠道
    String? currentChannel,

    /// 已生成的文件列表
    @Default([]) List<String> generatedFiles,

    /// 错误信息
    String? errorMessage,

    /// 创建时间
    required DateTime createdAt,

    /// 完成时间
    DateTime? completedAt,
  }) = _ChannelPackTask;

  const ChannelPackTask._();
}
