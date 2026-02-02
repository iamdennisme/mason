import 'package:flutter/material.dart';

/// 扩展方法
class Extensions {
  Extensions._();
}

/// String 扩展
extension StringExtensions on String {
  /// 是否为空或纯空白
  bool get isBlank => trim().isEmpty;

  /// 是否不为空且非纯空白
  bool get isNotBlank => trim().isNotEmpty;
}

/// BuildContext 扩展
extension ContextExtensions on BuildContext {
  /// 主题
  ThemeData get theme => Theme.of(this);

  /// 颜色方案
  ColorScheme get colorScheme => Theme.of(this).colorScheme;

  /// 文本主题
  TextTheme get textTheme => Theme.of(this).textTheme;

  /// 媒体查询
  MediaQueryData get mediaQuery => MediaQuery.of(this);

  /// 屏幕尺寸
  Size get screenSize => mediaQuery.size;

  /// 屏幕宽度
  double get screenWidth => screenSize.width;

  /// 屏幕高度
  double get screenHeight => screenSize.height;

  /// 是否为移动端（宽度 < 600）
  bool get isMobile => screenWidth < 600;

  /// 是否为平板（600 <= 宽度 < 900）
  bool get isTablet => screenWidth >= 600 && screenWidth < 900;

  /// 是否为桌面端（宽度 >= 900）
  bool get isDesktop => screenWidth >= 900;

  /// 显示 Snackbar
  void showSnackBar(String message, {SnackBarAction? action}) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Text(message),
        action: action,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  /// 隐藏键盘
  void hideKeyboard() {
    FocusScope.of(this).unfocus();
  }
}
