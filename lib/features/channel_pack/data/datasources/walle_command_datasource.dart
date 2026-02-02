import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:process_run/shell_run.dart';
import '../../../../core/constants/app_constants.dart';

/// Walle 命令行数据源
/// 负责与 Walle JAR 文件交互，执行渠道打包命令
class WalleCommandDatasource {
  WalleCommandDatasource._();

  static final WalleCommandDatasource _instance = WalleCommandDatasource._();
  static WalleCommandDatasource get instance => _instance;

  File? _walleJarFile;

  /// 获取 Walle JAR 文件
  Future<File> getWalleJarFile() async {
    if (_walleJarFile != null && await _walleJarFile!.exists()) {
      return _walleJarFile!;
    }

    final appDir = await getApplicationSupportDirectory();
    final walleDir = Directory(p.join(appDir.path, 'walle'));

    if (!(await walleDir.exists())) {
      await walleDir.create(recursive: true);
    }

    _walleJarFile = File(p.join(walleDir.path, 'walle-cli-all.jar'));

    // 如果文件不存在，需要用户手动下载
    if (!(await _walleJarFile!.exists())) {
      throw WalleJarNotFoundException(
        'Walle JAR 文件未找到，请下载后放置到: ${walleDir.path}\n'
        '下载地址: ${AppConstants.walleDownloadUrl}',
      );
    }

    return _walleJarFile!;
  }

  /// 检查 Walle JAR 是否存在
  Future<bool> isWalleJarExists() async {
    try {
      final jarFile = await getWalleJarFile();
      return await jarFile.exists();
    } catch (_) {
      return false;
    }
  }

  /// 执行渠道打包命令
  ///
  /// [apkPath] 原始 APK 文件路径
  /// [outputDir] 输出目录
  /// [channels] 渠道列表
  /// [onProgress] 进度回调
  Future<List<String>> batchPut(
    String apkPath,
    String outputDir,
    List<String> channels, {
    void Function(String channel, int current, int total)? onProgress,
  }) async {
    if (!(await File(apkPath).exists())) {
      throw ApkNotFoundException('APK 文件不存在: $apkPath');
    }

    if (channels.isEmpty) {
      throw const InvalidChannelsException('渠道列表不能为空');
    }

    final jarFile = await getWalleJarFile();
    final outputDirectory = Directory(outputDir);
    if (!(await outputDirectory.exists())) {
      await outputDirectory.create(recursive: true);
    }

    final List<String> generatedFiles = [];
    final List<String> errors = [];

    for (int i = 0; i < channels.length; i++) {
      final channel = channels[i];
      onProgress?.call(channel, i + 1, channels.length);

      final channelFileName =
          '${p.basenameWithoutExtension(apkPath)}_$channel${p.extension(apkPath)}';
      final outputPath = p.join(outputDir, channelFileName);

      try {
        await _putChannel(jarFile.path, apkPath, outputPath, channel);
        generatedFiles.add(outputPath);
      } catch (e) {
        errors.add('$channel: $e');
      }
    }

    if (errors.isNotEmpty) {
      throw ChannelPackException('部分渠道打包失败:\n${errors.join('\n')}');
    }

    return generatedFiles;
  }

  /// 单个渠道打包
  Future<void> _putChannel(
    String jarPath,
    String apkPath,
    String outputPath,
    String channel,
  ) async {
    final shell = Shell();

    // 构建命令: java -jar walle-cli-all.jar put --channel <channel> <apk> <output>
    final result = await shell.run(
      'java -jar "$jarPath" put --channel "$channel" "$apkPath" "$outputPath"',
    );

    // process_run 返回 ProcessResult 列表
    final hasErrors = result.any((r) => r.exitCode != 0);
    if (hasErrors) {
      final errorText = result
          .where((r) => r.exitCode != 0)
          .map((r) => r.stderr.toString())
          .where((s) => s.isNotEmpty)
          .join('\n');
      throw ChannelPackException('Walle 命令执行失败: $errorText');
    }
  }

  /// 获取 APK 信息
  Future<ApkInfo> getApkInfo(String apkPath) async {
    if (!(await File(apkPath).exists())) {
      throw ApkNotFoundException('APK 文件不存在: $apkPath');
    }

    final jarFile = await getWalleJarFile();
    final shell = Shell();

    // 获取渠道信息: java -jar walle-cli-all.jar show <apk>
    final result = await shell.run(
      'java -jar "${jarFile.path}" show "$apkPath"',
    );

    final infoText = result
        .map((r) => r.stdout.toString())
        .where((s) => s.isNotEmpty)
        .join('\n');

    return ApkInfo(
      path: apkPath,
      name: p.basename(apkPath),
      size: await File(apkPath).length(),
      channelInfo: infoText,
    );
  }

  /// 初始化 Walle（下载提示等）
  Future<WalleInitResult> initWalle() async {
    final exists = await isWalleJarExists();

    if (exists) {
      final jarFile = await getWalleJarFile();
      return WalleInitResult(
        isInstalled: true,
        version: AppConstants.walleVersion,
        path: jarFile.path,
      );
    }

    final appDir = await getApplicationSupportDirectory();
    final walleDir = Directory(p.join(appDir.path, 'walle'));
    final targetPath = p.join(walleDir.path, 'walle-cli-all.jar');

    return WalleInitResult(
      isInstalled: false,
      version: AppConstants.walleVersion,
      path: targetPath,
      downloadUrl: AppConstants.walleDownloadUrl,
    );
  }
}

/// APK 信息
class ApkInfo {
  final String path;
  final String name;
  final int size;
  final String channelInfo;

  const ApkInfo({
    required this.path,
    required this.name,
    required this.size,
    required this.channelInfo,
  });

  @override
  String toString() {
    return 'ApkInfo(path: $path, name: $name, size: $size)';
  }
}

/// Walle 初始化结果
class WalleInitResult {
  final bool isInstalled;
  final String version;
  final String path;
  final String? downloadUrl;

  const WalleInitResult({
    required this.isInstalled,
    required this.version,
    required this.path,
    this.downloadUrl,
  });
}

/// Walle JAR 文件未找到异常
class WalleJarNotFoundException implements Exception {
  final String message;
  WalleJarNotFoundException(this.message);

  @override
  String toString() => message;
}

/// APK 文件未找到异常
class ApkNotFoundException implements Exception {
  final String message;
  ApkNotFoundException(this.message);

  @override
  String toString() => message;
}

/// 无效渠道异常
class InvalidChannelsException implements Exception {
  final String message;
  const InvalidChannelsException(this.message);

  @override
  String toString() => message;
}

/// 渠道打包异常
class ChannelPackException implements Exception {
  final String message;
  ChannelPackException(this.message);

  @override
  String toString() => message;
}
