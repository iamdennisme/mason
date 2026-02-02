import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;

/// Java 环境管理
/// 负责检测和管理 Java 运行环境
/// JRE 已内嵌到原生工程中
class JavaManager {
  JavaManager._();

  static final JavaManager _instance = JavaManager._();
  static JavaManager get instance => _instance;

  File? _javaExecutable;
  bool _isInitialized = false;

  /// 获取 Java 可执行文件路径
  Future<File> getJavaExecutable() async {
    if (_isInitialized && _javaExecutable != null) {
      return _javaExecutable!;
    }

    // 直接使用内嵌 JRE
    final embeddedJre = await _getBundledJre();
    _javaExecutable = embeddedJre;
    _isInitialized = true;
    return embeddedJre;
  }

  /// 检查 Java 是否可用
  Future<JavaStatus> checkJavaStatus() async {
    try {
      final java = await getJavaExecutable();
      final result = await Process.run(
        java.path,
        ['-version'],
      );

      if (result.exitCode == 0) {
        final versionOutput = result.stderr.toString() +
                              result.stdout.toString();
        return JavaStatus(
          isInstalled: true,
          javaPath: java.path,
          version: _parseJavaVersion(versionOutput),
          isEmbedded: _isEmbeddedJava(java.path),
        );
      }
    } catch (_) {}

    return JavaStatus(
      isInstalled: false,
      canExtract: false,
      isEmbedded: true,
    );
  }

  /// 获取内嵌 JRE 路径
  Future<File> _getBundledJre() async {
    // 开发环境：JRE 直接在原生工程目录中
    if (kDebugMode) {
      return await _getDevJre();
    }

    // 生产环境：JRE 在 app bundle 或可执行文件目录中
    return await _getProductionJre();
  }

  /// 获取开发环境的 JRE（从原生工程目录）
  Future<File> _getDevJre() async {
    final executable = Platform.resolvedExecutable;
    debugPrint('=== JRE 查找调试 ===');
    debugPrint('可执行文件: $executable');
    debugPrint('当前工作目录: ${Directory.current.path}');

    if (Platform.isMacOS) {
      // executable 指向: build/macos/Build/Products/Debug/mason.app/Contents/MacOS/mason
      // 向上4层: build/macos/Build/Products/Debug
      final buildProductsDir = p.dirname(p.dirname(p.dirname(p.dirname(executable))));
      debugPrint('buildProductsDir: $buildProductsDir');
      // 再向上2层: build/macos
      final buildMacosDir = p.dirname(p.dirname(buildProductsDir));
      debugPrint('buildMacosDir: $buildMacosDir');
      // 再向上3层: project root (mason/)
      // buildMacosDir -> build/macos/Build -> build/macos -> build -> projectRoot
      final projectRoot = p.dirname(p.dirname(p.dirname(buildMacosDir)));
      debugPrint('projectRoot: $projectRoot');

      // 尝试多个可能的路径
      final possiblePaths = [
        // 从项目根目录的源代码中找 JRE
        p.join(projectRoot, 'macos', 'Runner', 'jre', 'Contents', 'Home', 'bin', 'java'),
        // build/macos/Runner/jre/Contents/Home/bin/java (如果构建时复制了)
        p.join(buildMacosDir, 'Runner', 'jre', 'Contents', 'Home', 'bin', 'java'),
        // 从 build 目录找 macos 源代码
        p.join(buildMacosDir, '..', 'macos', 'Runner', 'jre', 'Contents', 'Home', 'bin', 'java'),
        // 备选：使用当前工作目录
        p.join(Directory.current.path, 'macos', 'Runner', 'jre', 'Contents', 'Home', 'bin', 'java'),
      ];

      debugPrint('尝试的 JRE 路径:');
      for (final path in possiblePaths) {
        final normalizedPath = p.normalize(path);
        debugPrint('  - $normalizedPath');
        final file = File(normalizedPath);
        final exists = await file.exists();
        debugPrint('    存在: $exists');
        if (exists) {
          debugPrint('✓ 找到 JRE: $normalizedPath');
          return file;
        }
      }
    } else if (Platform.isWindows) {
      // executable 指向: build\windows\runner\Debug\mason.exe
      // 向上3层: build/windows
      final buildWindowsDir = p.dirname(p.dirname(p.dirname(executable)));
      debugPrint('buildWindowsDir: $buildWindowsDir');
      // 再向上2层: project root
      // buildWindowsDir -> build/windows -> build -> projectRoot
      final projectRoot = p.dirname(p.dirname(buildWindowsDir));
      debugPrint('projectRoot: $projectRoot');

      final possiblePaths = [
        // 从项目根目录的源代码中找 JRE
        p.join(projectRoot, 'windows', 'runner', 'jre', 'bin', 'java.exe'),
        // build/windows/runner/jre/bin/java.exe (如果构建时复制了)
        p.join(buildWindowsDir, 'runner', 'jre', 'bin', 'java.exe'),
        // 备选：使用当前工作目录
        p.join(Directory.current.path, 'windows', 'runner', 'jre', 'bin', 'java.exe'),
      ];

      debugPrint('尝试的 JRE 路径:');
      for (final path in possiblePaths) {
        final normalizedPath = p.normalize(path);
        debugPrint('  - $normalizedPath');
        final file = File(normalizedPath);
        final exists = await file.exists();
        debugPrint('    存在: $exists');
        if (exists) {
          debugPrint('✓ 找到 JRE: $normalizedPath');
          return file;
        }
      }
    }

    debugPrint('✗ 未找到 JRE');
    throw JavaNotFoundException('开发环境 JRE 未找到');
  }

  /// 获取生产环境的 JRE
  Future<File> _getProductionJre() async {
    // macOS: JRE 应该在 app bundle 的 Resources 目录
    if (Platform.isMacOS) {
      // 获取 app bundle 路径
      final executable = Platform.resolvedExecutable;
      final appPath = p.dirname(p.dirname(p.dirname(executable)));
      final javaPath = p.join(
        appPath,
        'Contents',
        'Resources',
        'jre',
        'Contents',
        'Home',
        'bin',
        'java',
      );
      final file = File(javaPath);
      if (await file.exists()) {
        return file;
      }
    }

    // Windows: JRE 应该在可执行文件旁边的 jre 目录
    if (Platform.isWindows) {
      final executable = Platform.resolvedExecutable;
      final appDir = p.dirname(executable);
      final javaPath = p.join(appDir, 'jre', 'bin', 'java.exe');
      final file = File(javaPath);
      if (await file.exists()) {
        return file;
      }
    }

    throw JavaNotFoundException('内嵌 JRE 未找到，请重新安装应用');
  }

  /// 判断是否是内嵌的 Java
  bool _isEmbeddedJava(String path) {
    return path.contains('jre');
  }

  /// 解析 Java 版本
  String _parseJavaVersion(String output) {
    // 输出格式示例: "java version \"1.8.0_xxx\"" 或 "openjdk version \"17.0.xxx\""
    final versionRegex = RegExp(r'version\s+"?(\d+\.\d+\.\d+[_\d]*)');
    final match = versionRegex.firstMatch(output);
    if (match != null) {
      return 'Java ${match.group(1)}';
    }
    return 'Java (未知版本)';
  }

  /// 重置初始化状态
  void reset() {
    _isInitialized = false;
    _javaExecutable = null;
  }
}

/// Java 状态
class JavaStatus {
  final bool isInstalled;
  final String? javaPath;
  final String? version;
  final bool isEmbedded;
  final bool canExtract;

  const JavaStatus({
    required this.isInstalled,
    this.javaPath,
    this.version,
    this.isEmbedded = false,
    this.canExtract = false,
  });

  @override
  String toString() {
    if (isInstalled) {
      final type = isEmbedded ? '内嵌' : '系统';
      return 'Java $version ($type)';
    } else {
      return 'Java 未就绪';
    }
  }
}

/// Java 未找到异常
class JavaNotFoundException implements Exception {
  final String message;
  JavaNotFoundException(this.message);

  @override
  String toString() => message;
}
