import '../../domain/entities/channel_pack_task.dart';
import '../../domain/repositories/channel_pack_repository.dart';
import '../datasources/walle_command_datasource.dart';

/// 渠道打包仓库实现
class ChannelPackRepositoryImpl implements ChannelPackRepository {
  final WalleCommandDatasource _datasource = WalleCommandDatasource.instance;

  @override
  Future<List<String>> executePack(
    ChannelPackTask task, {
    void Function(String channel, int current, int total)? onProgress,
  }) async {
    return await _datasource.batchPut(
      task.apkPath,
      task.outputDir,
      task.channels,
      onProgress: onProgress,
    );
  }

  @override
  Future<ApkInfoEntity> getApkInfo(String apkPath) async {
    final info = await _datasource.getApkInfo(apkPath);
    return ApkInfoEntity(
      path: info.path,
      name: info.name,
      size: info.size,
      channel: _extractChannel(info.channelInfo),
    );
  }

  @override
  Future<WalleStatus> checkWalleStatus() async {
    final result = await _datasource.initWalle();
    return WalleStatus(
      isInstalled: result.isInstalled,
      version: result.version,
      path: result.path,
      downloadUrl: result.downloadUrl,
    );
  }

  /// 从渠道信息中提取渠道名称
  String? _extractChannel(String channelInfo) {
    // Walle show 命令输出格式示例:
    // [...]
    // Channel: 'google'
    // [...]
    final channelRegex = RegExp(r"Channel:\s*'([^']+)'");
    final match = channelRegex.firstMatch(channelInfo);
    return match?.group(1);
  }
}
