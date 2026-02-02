import 'package:flutter/material.dart';
import '../../features/channel_pack/presentation/pages/channel_pack_page.dart';
import '../utils/extensions.dart';

/// 应用路由
class AppRouter {
  AppRouter._();

  /// 路由列表
  static const String home = '/';
  static const String channelPack = '/channel-pack';

  /// 路由生成器
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case home:
      case channelPack:
        return MaterialPageRoute(
          builder: (_) => const ChannelPackPage(),
          settings: settings,
        );
      default:
        return MaterialPageRoute(
          builder: (_) => const _NotFoundPage(),
          settings: settings,
        );
    }
  }
}

/// 404 页面
class _NotFoundPage extends StatelessWidget {
  const _NotFoundPage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('页面未找到')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              '页面未找到',
              style: context.textTheme.headlineMedium,
            ),
          ],
        ),
      ),
    );
  }
}
