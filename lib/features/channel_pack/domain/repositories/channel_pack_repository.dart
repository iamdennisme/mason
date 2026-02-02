import '../entities/channel_pack_task.dart';

/// 渠道打包仓库接口
abstract class ChannelPackRepository {
  /// 执行渠道打包
  ///
  /// [task] 打包任务
  /// [onProgress] 进度回调
  Future<List<String>> executePack(
    ChannelPackTask task, {
    void Function(String channel, int current, int total)? onProgress,
  });

  /// 获取 APK 信息
  Future<ApkInfoEntity> getApkInfo(String apkPath);

  /// 检查 Walle 是否已安装
  Future<WalleStatus> checkWalleStatus();
}

/// APK 信息实体
class ApkInfoEntity {
  final String path;
  final String name;
  final int size;
  final String? channel;

  const ApkInfoEntity({
    required this.path,
    required this.name,
    required this.size,
    this.channel,
  });

  @override
  String toString() {
    return 'ApkInfoEntity(path: $path, name: $name, size: $size, channel: $channel)';
  }
}

/// Walle 状态
class WalleStatus {
  final bool isInstalled;
  final String? version;
  final String? path;
  final String? downloadUrl;

  const WalleStatus({
    required this.isInstalled,
    this.version,
    this.path,
    this.downloadUrl,
  });
}
