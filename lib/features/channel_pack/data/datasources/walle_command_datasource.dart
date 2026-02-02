import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/java_manager.dart';

/// Walle 命令行数据源
/// 负责与 Walle JAR 文件交互，执行渠道打包命令
/// Walle JAR 从应用 assets 中复制，无需下载
class WalleCommandDatasource {
  WalleCommandDatasource._();

  static final WalleCommandDatasource _instance = WalleCommandDatasource._();
  static WalleCommandDatasource get instance => _instance;

  File? _walleJarFile;
  File? _javaExecutable;
  bool _isCopying = false;

  /// 获取 Java 可执行文件
  Future<File> _getJavaExecutable() async {
    if (_javaExecutable != null && await _javaExecutable!.exists()) {
      return _javaExecutable!;
    }
    _javaExecutable = await JavaManager.instance.getJavaExecutable();
    return _javaExecutable!;
  }

  /// 获取 Walle JAR 文件
  /// 首次调用时会从 assets 复制到应用目录
  Future<File> getWalleJarFile() async {
    if (_isCopying) {
      // 等待复制完成
      while (_isCopying) {
        await Future.delayed(const Duration(milliseconds: 100));
      }
    }

    if (_walleJarFile != null && await _walleJarFile!.exists()) {
      return _walleJarFile!;
    }

    _isCopying = true;
    try {
      final appDir = await getApplicationSupportDirectory();
      final walleDir = Directory(p.join(appDir.path, 'walle'));

      if (!(await walleDir.exists())) {
        await walleDir.create(recursive: true);
      }

      _walleJarFile = File(p.join(walleDir.path, 'walle-cli-all.jar'));

      // 如果文件不存在，从 assets 复制
      if (!(await _walleJarFile!.exists())) {
        await _copyWalleJarFromAssets(_walleJarFile!);
      }

      return _walleJarFile!;
    } finally {
      _isCopying = false;
    }
  }

  /// 从 assets 复制 Walle JAR
  Future<void> _copyWalleJarFromAssets(File targetFile) async {
    try {
      // 从 assets 加载 Walle JAR
      final byteData = await rootBundle.load('assets/walle/walle-cli-all.jar');
      final bytes = byteData.buffer.asUint8List();

      // 写入目标文件
      await targetFile.writeAsBytes(bytes);
    } catch (e) {
      throw WalleJarNotFoundException('Walle JAR 复制失败: $e');
    }
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

  /// 检查环境是否就绪
  Future<EnvironmentStatus> checkEnvironment() async {
    final status = EnvironmentStatus();

    // 检查 Java
    try {
      final java = await _getJavaExecutable();
      final result = await Process.run(java.path, ['-version']);
      if (result.exitCode == 0) {
        final versionOutput = result.stderr.toString() +
                              result.stdout.toString();
        status.javaInstalled = true;
        status.javaVersion = _parseJavaVersion(versionOutput);
        status.javaPath = java.path;
      }
    } catch (_) {
      status.javaInstalled = false;
    }

    // 检查 Walle JAR（总是存在，因为已打包）
    try {
      final jarFile = await getWalleJarFile();
      status.walleJarExists = true;
      status.walleJarPath = jarFile.path;
    } catch (_) {
      status.walleJarExists = false;
    }

    status.isReady = status.javaInstalled;
    return status;
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
    debugPrint('=== 开始批量打包 ===');
    debugPrint('APK: $apkPath');
    debugPrint('输出目录: $outputDir');
    debugPrint('渠道列表: $channels');

    if (!(await File(apkPath).exists())) {
      throw ApkNotFoundException('APK 文件不存在: $apkPath');
    }

    if (channels.isEmpty) {
      throw const InvalidChannelsException('渠道列表不能为空');
    }

    final jarFile = await getWalleJarFile();
    final java = await _getJavaExecutable();
    debugPrint('Java: ${java.path}');
    debugPrint('Walle JAR: ${jarFile.path}');

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

      debugPrint('处理渠道: $channel -> $outputPath');

      try {
        await _putChannel(java.path, jarFile.path, apkPath, outputPath, channel);
        generatedFiles.add(outputPath);
        debugPrint('✓ 渠道 $channel 打包成功');
      } catch (e) {
        debugPrint('✗ 渠道 $channel 打包失败: $e');
        errors.add('$channel: $e');
      }
    }

    if (errors.isNotEmpty) {
      throw ChannelPackException('部分渠道打包失败:\n${errors.join('\n')}');
    }

    debugPrint('=== 批量打包完成，生成了 ${generatedFiles.length} 个文件 ===');
    return generatedFiles;
  }

  /// 单个渠道打包
  Future<void> _putChannel(
    String javaPath,
    String jarPath,
    String apkPath,
    String outputPath,
    String channel,
  ) async {
    // 构建命令: java -jar walle-cli-all.jar put --channel <channel> <apk> <output>
    final args = [
      '-jar',
      jarPath,
      'put',
      '--channel',
      channel,
      apkPath,
      outputPath,
    ];

    debugPrint('执行命令: $javaPath ${args.join(' ')}');

    final result = await Process.run(javaPath, args);

    debugPrint('退出码: ${result.exitCode}');
    if (result.stdout.toString().isNotEmpty) {
      debugPrint('stdout: ${result.stdout}');
    }
    if (result.stderr.toString().isNotEmpty) {
      debugPrint('stderr: ${result.stderr}');
    }

    if (result.exitCode != 0) {
      final errorText = result.stderr.toString().trim();
      final stdoutText = result.stdout.toString().trim();
      throw ChannelPackException(
        'Walle 命令执行失败\n'
        '渠道: $channel\n'
        '${errorText.isNotEmpty ? "错误: $errorText" : stdoutText}',
      );
    }
  }

  /// 获取 APK 信息
  Future<ApkInfo> getApkInfo(String apkPath) async {
    if (!(await File(apkPath).exists())) {
      throw ApkNotFoundException('APK 文件不存在: $apkPath');
    }

    final jarFile = await getWalleJarFile();
    final java = await _getJavaExecutable();

    // 获取渠道信息: java -jar walle-cli-all.jar show <apk>
    final args = [
      '-jar',
      jarFile.path,
      'show',
      apkPath,
    ];

    final result = await Process.run(java.path, args);

    final infoText = result.stdout.toString().trim();

    return ApkInfo(
      path: apkPath,
      name: p.basename(apkPath),
      size: await File(apkPath).length(),
      channelInfo: infoText,
    );
  }

  /// 初始化 Walle
  Future<WalleInitResult> initWalle() async {
    final jarFile = await getWalleJarFile();
    return WalleInitResult(
      isInstalled: true,
      version: AppConstants.walleVersion,
      path: jarFile.path,
    );
  }

  /// 解析 Java 版本
  String _parseJavaVersion(String output) {
    final versionRegex = RegExp(r'version\s+"?(\d+\.\d+\.\d+[_\d]*)');
    final match = versionRegex.firstMatch(output);
    if (match != null) {
      return match.group(1)!;
    }
    return 'unknown';
  }
}

/// 环境状态
class EnvironmentStatus {
  bool isReady = false;
  bool javaInstalled = false;
  String? javaVersion;
  String? javaPath;
  bool walleJarExists = false;
  String? walleJarPath;
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
