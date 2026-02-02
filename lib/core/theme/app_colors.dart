import 'package:flutter/material.dart';

/// 应用颜色主题 - 极简专业风格
/// 参考 GitHub/Linear/Stripe 的设计语言
class AppColors {
  AppColors._();

  // ========== 基础色系 ==========
  static const Color background = Color(0xFF0D1117);      // 主背景
  static const Color surface = Color(0xFF161B22);         // 卡片/表面
  static const Color surfaceVariant = Color(0xFF21262D);  // 变体表面

  // 文本色
  static const Color textPrimary = Color(0xFFE6EDF3);     // 主要文本
  static const Color textSecondary = Color(0xFF8B949E);   // 次要文本
  static const Color textTertiary = Color(0xFF6E7681);    // 三级文本

  // 强调色 - 使用单一的蓝色作为主色
  static const Color primary = Color(0xFF58A6FF);         // 主色（蓝）
  static const Color primaryHover = Color(0xFF79C0FF);    // 主色悬停
  static const Color accent = Color(0xFF238636);          // 强调色（绿）

  // 状态色
  static const Color success = Color(0xFF238636);
  static const Color warning = Color(0xFFD29922);
  static const Color error = Color(0xFFDA3633);
  static const Color info = Color(0xFF58A6FF);

  // 边框色
  static const Color border = Color(0xFF30363D);
  static const Color borderHover = Color(0xFF8B949E);

  // ========== 透明度变体 ==========
  static Color withOpacity(Color color, double opacity) =>
      color.withValues(alpha: opacity);
}
