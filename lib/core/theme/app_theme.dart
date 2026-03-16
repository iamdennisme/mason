import 'dart:io';
import 'package:flutter/material.dart';
import 'app_colors.dart';

/// 应用主题配置
class AppTheme {
  AppTheme._();

  /// 是否为 Windows 平台
  static bool get _isWindows => Platform.isWindows;

  /// 获取平台优化的字体系列
  ///
  /// Windows 使用 Segoe UI（系统默认）
  /// macOS 使用 San Francisco（系统默认）
  /// Linux 使用 Noto Sans 或系统默认
  static String? get _platformFontFamily {
    if (_isWindows) {
      // Windows 10/11 使用 Segoe UI
      return 'Segoe UI';
    }
    // 其他平台使用系统默认
    return null;
  }

  /// 获取等宽字体
  ///
  /// Windows 使用 Consolas（更清晰）
  /// macOS 使用 Menlo
  /// 其他使用 JetBrains Mono
  static String get monospaceFontFamily {
    if (_isWindows) {
      return 'Consolas';
    } else if (Platform.isMacOS) {
      return 'Menlo';
    }
    return 'JetBrains Mono';
  }

  /// 深色主题
  static ThemeData get darkTheme {
    // 平台特定的文本样式优化
    final baseTextStyle = TextStyle(
      fontFamily: _platformFontFamily,
      // Windows 上的渲染优化
      height: _isWindows ? 1.4 : 1.5,
      letterSpacing: _isWindows ? 0.0 : -0.2,
      // 启用更清晰的文本渲染
      debugLabel: _isWindows ? 'Windows Optimized' : 'Default',
    );

    return ThemeData(
      useMaterial3: true,

      // 颜色方案
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primary,
        onPrimary: Colors.white,
        secondary: AppColors.primaryHover,
        onSecondary: Colors.white,
        surface: AppColors.surface,
        onSurface: AppColors.textPrimary,
        error: AppColors.error,
        onError: Colors.white,
      ),

      // 脚手架背景
      scaffoldBackgroundColor: AppColors.background,

      // AppBar 主题
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.surfaceVariant,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: baseTextStyle.copyWith(
          color: AppColors.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),

      // 卡片主题
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        clipBehavior: Clip.antiAlias,
        // Windows 使用稍小的圆角
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_isWindows ? 6 : 8),
          side: const BorderSide(color: AppColors.border, width: 1),
        ),
      ),

      // 输入框主题
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceVariant,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_isWindows ? 6 : 8),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_isWindows ? 6 : 8),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_isWindows ? 6 : 8),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_isWindows ? 6 : 8),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: baseTextStyle.copyWith(
          color: AppColors.textSecondary,
          fontSize: 14,
        ),
      ),

      // 按钮主题
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_isWindows ? 6 : 8),
          ),
          textStyle: baseTextStyle.copyWith(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textPrimary,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_isWindows ? 6 : 8),
            side: const BorderSide(color: AppColors.border),
          ),
          textStyle: baseTextStyle.copyWith(
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          textStyle: baseTextStyle.copyWith(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),

      // 文本主题 - 平台优化
      textTheme: TextTheme(
        displayLarge: baseTextStyle.copyWith(
          color: AppColors.textPrimary,
          fontSize: 32,
          fontWeight: FontWeight.bold,
          height: 1.2,
        ),
        displayMedium: baseTextStyle.copyWith(
          color: AppColors.textPrimary,
          fontSize: 28,
          fontWeight: FontWeight.bold,
          height: 1.2,
        ),
        displaySmall: baseTextStyle.copyWith(
          color: AppColors.textPrimary,
          fontSize: 24,
          fontWeight: FontWeight.bold,
          height: 1.3,
        ),
        headlineLarge: baseTextStyle.copyWith(
          color: AppColors.textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w600,
          height: 1.3,
        ),
        headlineMedium: baseTextStyle.copyWith(
          color: AppColors.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w600,
          height: 1.3,
        ),
        titleLarge: baseTextStyle.copyWith(
          color: AppColors.textPrimary,
          fontSize: 16,
          fontWeight: FontWeight.w600,
          height: 1.4,
        ),
        titleMedium: baseTextStyle.copyWith(
          color: AppColors.textPrimary,
          fontSize: 14,
          fontWeight: FontWeight.w500,
          height: 1.4,
        ),
        bodyLarge: baseTextStyle.copyWith(
          color: AppColors.textPrimary,
          fontSize: 15,
          height: 1.5,
        ),
        bodyMedium: baseTextStyle.copyWith(
          color: AppColors.textPrimary,
          fontSize: 14,
          height: 1.5,
        ),
        bodySmall: baseTextStyle.copyWith(
          color: AppColors.textSecondary,
          fontSize: 12,
          height: 1.4,
        ),
        labelLarge: baseTextStyle.copyWith(
          color: AppColors.textPrimary,
          fontSize: 14,
          fontWeight: FontWeight.w500,
          height: 1.4,
        ),
        labelMedium: baseTextStyle.copyWith(
          color: AppColors.textSecondary,
          fontSize: 12,
          fontWeight: FontWeight.w500,
          height: 1.4,
        ),
        labelSmall: baseTextStyle.copyWith(
          color: AppColors.textTertiary,
          fontSize: 11,
          fontWeight: FontWeight.w500,
          height: 1.4,
        ),
      ),

      // 代码/等宽字体主题
      fontFamily: monospaceFontFamily,

      // 分割线主题
      dividerTheme: const DividerThemeData(
        color: AppColors.border,
        thickness: 1,
        space: 1,
      ),

      // 图标主题
      iconTheme: const IconThemeData(
        color: AppColors.textSecondary,
        size: 24,
      ),

      // List Tile 主题
      listTileTheme: ListTileThemeData(
        iconColor: AppColors.textSecondary,
        textColor: AppColors.textPrimary,
        tileColor: Colors.transparent,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_isWindows ? 4 : 8),
        ),
      ),

      // 对话框主题
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_isWindows ? 8 : 12),
        ),
        titleTextStyle: baseTextStyle.copyWith(
          color: AppColors.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
        contentTextStyle: baseTextStyle.copyWith(
          color: AppColors.textPrimary,
          fontSize: 14,
        ),
        elevation: 0,
      ),

      // SnackBar 主题
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.surfaceVariant,
        contentTextStyle: baseTextStyle.copyWith(
          color: AppColors.textPrimary,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_isWindows ? 6 : 8),
        ),
        behavior: SnackBarBehavior.floating,
        elevation: 0,
      ),

      // 滚动条主题
      scrollbarTheme: ScrollbarThemeData(
        thumbColor: WidgetStateProperty.all(AppColors.surfaceVariant),
        trackColor: WidgetStateProperty.all(AppColors.surfaceVariant.withValues(alpha: 0.3)),
        trackBorderColor: WidgetStateProperty.all(Colors.transparent),
        thickness: WidgetStateProperty.all(_isWindows ? 8 : 6),
        radius: Radius.circular(_isWindows ? 4 : 3),
        crossAxisMargin: 4,
        mainAxisMargin: 4,
      ),

      // Chip 主题
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surfaceVariant,
        labelStyle: baseTextStyle.copyWith(
          color: AppColors.textPrimary,
          fontSize: 13,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_isWindows ? 4 : 6),
        ),
        side: BorderSide.none,
      ),

      // Tooltip 主题
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(_isWindows ? 4 : 6),
        ),
        textStyle: baseTextStyle.copyWith(
          color: AppColors.textPrimary,
          fontSize: 12,
        ),
      ),
    );
  }

  /// 浅色主题（可选，当前主要使用深色主题）
  static ThemeData get lightTheme {
    return ThemeData.light();
  }
}
