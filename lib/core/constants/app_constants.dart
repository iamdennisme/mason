/// 应用常量
class AppConstants {
  AppConstants._();

  // Walle 相关常量
  static const String walleVersion = '1.1.6';
  static const String walleDownloadUrl =
      'https://github.com/Meituan-Dianping/walle/releases/download/v$walleVersion/walle-cli-all.jar';

  // 应用信息
  static const String appName = 'Mason';
  static const String appVersion = '1.0.0';
}

/// 打包状态
enum PackStatus {
  idle,      // 空闲
  packing,   // 打包中
  completed, // 完成
  failed,    // 失败
}
