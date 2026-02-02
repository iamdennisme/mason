import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../data/repositories/channel_pack_repository.dart';
import '../../domain/entities/channel_pack_task.dart';
import '../../domain/repositories/channel_pack_repository.dart' as domain;
import '../../../../core/constants/app_constants.dart';

/// 仓库提供者
final channelPackRepositoryProvider = Provider<ChannelPackRepositoryImpl>((ref) {
  return ChannelPackRepositoryImpl();
});

/// Walle 状态提供者
final walleStatusProvider = FutureProvider<domain.WalleStatus>((ref) async {
  final repository = ref.read(channelPackRepositoryProvider);
  return await repository.checkWalleStatus();
});

/// 当前任务提供者
final currentTaskProvider = NotifierProvider<CurrentTaskNotifier, ChannelPackTask?>(
  CurrentTaskNotifier.new,
);

/// 当前任务通知器
class CurrentTaskNotifier extends Notifier<ChannelPackTask?> {
  @override
  ChannelPackTask? build() => null;

  void set(ChannelPackTask? task) => state = task;
}

/// 打包状态
sealed class PackState {
  const PackState();

  static const idle = PackStateIdle();

  static PackState packing({
    required String currentChannel,
    required int current,
    required int total,
    required double progress,
  }) =>
      PackStatePacking(
        currentChannel: currentChannel,
        current: current,
        total: total,
        progress: progress,
      );

  static PackState completed({
    required List<String> generatedFiles,
    required Duration duration,
  }) =>
      PackStateCompleted(
        generatedFiles: generatedFiles,
        duration: duration,
      );

  static PackState failed(String error) => PackStateFailed(error: error);

  T when<T>({
    required T Function() idle,
    required T Function(String currentChannel, int current, int total,
            double progress)
        packing,
    required T Function(List<String> generatedFiles, Duration duration) completed,
    required T Function(String error) failed,
  }) {
    if (this is PackStateIdle) {
      return idle();
    } else if (this is PackStatePacking) {
      final self = this as PackStatePacking;
      return packing(
        self.currentChannel,
        self.current,
        self.total,
        self.progress,
      );
    } else if (this is PackStateCompleted) {
      final self = this as PackStateCompleted;
      return completed(self.generatedFiles, self.duration);
    } else {
      final self = this as PackStateFailed;
      return failed(self.error);
    }
  }
}

class PackStateIdle extends PackState {
  const PackStateIdle();
}

class PackStatePacking extends PackState {
  final String currentChannel;
  final int current;
  final int total;
  final double progress;

  PackStatePacking({
    required this.currentChannel,
    required this.current,
    required this.total,
    required this.progress,
  });
}

class PackStateCompleted extends PackState {
  final List<String> generatedFiles;
  final Duration duration;

  PackStateCompleted({
    required this.generatedFiles,
    required this.duration,
  });
}

class PackStateFailed extends PackState {
  final String error;

  PackStateFailed({required this.error});
}

/// 打包状态提供者
final packStateProvider = NotifierProvider<PackStateNotifier, PackState>(
  PackStateNotifier.new,
);

/// 打包状态通知器
class PackStateNotifier extends Notifier<PackState> {
  @override
  PackState build() => PackState.idle;

  void setIdle() => state = PackState.idle;

  void setPacking({
    required String currentChannel,
    required int current,
    required int total,
    required double progress,
  }) {
    state = PackState.packing(
      currentChannel: currentChannel,
      current: current,
      total: total,
      progress: progress,
    );
  }

  void setCompleted({
    required List<String> generatedFiles,
    required Duration duration,
  }) {
    state = PackState.completed(
      generatedFiles: generatedFiles,
      duration: duration,
    );
  }

  void setFailed(String error) => state = PackState.failed(error);
}

/// 打包操作提供者
final packNotifierProvider = Provider<PackNotifier>((ref) {
  return PackNotifier(ref);
});

/// 打包通知器
class PackNotifier extends ChangeNotifier {
  final Ref _ref;

  PackNotifier(this._ref);

  ChannelPackTask? _currentTask;

  ChannelPackTask? get currentTask => _currentTask;

  /// 开始打包
  Future<void> startPack({
    required String apkPath,
    required String outputDir,
    required List<String> channels,
  }) async {
    if (channels.isEmpty) {
      _ref.read(packStateProvider.notifier).setFailed('请至少选择一个渠道');
      return;
    }

    final task = ChannelPackTask(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      apkPath: apkPath,
      outputDir: outputDir,
      channels: channels,
      status: PackStatus.packing,
      createdAt: DateTime.now(),
    );

    _currentTask = task;
    _ref.read(currentTaskProvider.notifier).set(task);
    _ref.read(packStateProvider.notifier).setPacking(
      currentChannel: '',
      current: 0,
      total: channels.length,
      progress: 0.0,
    );

    final startTime = DateTime.now();

    try {
      final repository = _ref.read(channelPackRepositoryProvider);

      final files = await repository.executePack(
        task,
        onProgress: (channel, current, total) {
          _ref.read(packStateProvider.notifier).setPacking(
            currentChannel: channel,
            current: current,
            total: total,
            progress: current / total,
          );
        },
      );

      final duration = DateTime.now().difference(startTime);
      _ref.read(packStateProvider.notifier).setCompleted(
        generatedFiles: files,
        duration: duration,
      );
    } catch (e) {
      _ref.read(packStateProvider.notifier).setFailed(e.toString());
    }
  }

  /// 重置状态
  void reset() {
    _currentTask = null;
    _ref.read(currentTaskProvider.notifier).set(null);
    _ref.read(packStateProvider.notifier).setIdle();
  }

  @override
  void dispose() {
    reset();
    super.dispose();
  }
}

/// APK 信息提供者
final apkInfoProvider = FutureProvider.family<domain.ApkInfoEntity, String>(
  (ref, path) async {
    final repository = ref.read(channelPackRepositoryProvider);
    return await repository.getApkInfo(path);
  },
);
