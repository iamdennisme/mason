// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'channel_pack_task.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ChannelPackTask {

/// 任务 ID
 String get id;/// 原始 APK 文件路径
 String get apkPath;/// 输出目录
 String get outputDir;/// 渠道列表
 List<String> get channels;/// 任务状态
 PackStatus get status;/// 当前进度 (0.0 - 1.0)
 double get progress;/// 当前正在处理的渠道
 String? get currentChannel;/// 已生成的文件列表
 List<String> get generatedFiles;/// 错误信息
 String? get errorMessage;/// 创建时间
 DateTime get createdAt;/// 完成时间
 DateTime? get completedAt;
/// Create a copy of ChannelPackTask
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ChannelPackTaskCopyWith<ChannelPackTask> get copyWith => _$ChannelPackTaskCopyWithImpl<ChannelPackTask>(this as ChannelPackTask, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ChannelPackTask&&(identical(other.id, id) || other.id == id)&&(identical(other.apkPath, apkPath) || other.apkPath == apkPath)&&(identical(other.outputDir, outputDir) || other.outputDir == outputDir)&&const DeepCollectionEquality().equals(other.channels, channels)&&(identical(other.status, status) || other.status == status)&&(identical(other.progress, progress) || other.progress == progress)&&(identical(other.currentChannel, currentChannel) || other.currentChannel == currentChannel)&&const DeepCollectionEquality().equals(other.generatedFiles, generatedFiles)&&(identical(other.errorMessage, errorMessage) || other.errorMessage == errorMessage)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.completedAt, completedAt) || other.completedAt == completedAt));
}


@override
int get hashCode => Object.hash(runtimeType,id,apkPath,outputDir,const DeepCollectionEquality().hash(channels),status,progress,currentChannel,const DeepCollectionEquality().hash(generatedFiles),errorMessage,createdAt,completedAt);

@override
String toString() {
  return 'ChannelPackTask(id: $id, apkPath: $apkPath, outputDir: $outputDir, channels: $channels, status: $status, progress: $progress, currentChannel: $currentChannel, generatedFiles: $generatedFiles, errorMessage: $errorMessage, createdAt: $createdAt, completedAt: $completedAt)';
}


}

/// @nodoc
abstract mixin class $ChannelPackTaskCopyWith<$Res>  {
  factory $ChannelPackTaskCopyWith(ChannelPackTask value, $Res Function(ChannelPackTask) _then) = _$ChannelPackTaskCopyWithImpl;
@useResult
$Res call({
 String id, String apkPath, String outputDir, List<String> channels, PackStatus status, double progress, String? currentChannel, List<String> generatedFiles, String? errorMessage, DateTime createdAt, DateTime? completedAt
});




}
/// @nodoc
class _$ChannelPackTaskCopyWithImpl<$Res>
    implements $ChannelPackTaskCopyWith<$Res> {
  _$ChannelPackTaskCopyWithImpl(this._self, this._then);

  final ChannelPackTask _self;
  final $Res Function(ChannelPackTask) _then;

/// Create a copy of ChannelPackTask
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? apkPath = null,Object? outputDir = null,Object? channels = null,Object? status = null,Object? progress = null,Object? currentChannel = freezed,Object? generatedFiles = null,Object? errorMessage = freezed,Object? createdAt = null,Object? completedAt = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,apkPath: null == apkPath ? _self.apkPath : apkPath // ignore: cast_nullable_to_non_nullable
as String,outputDir: null == outputDir ? _self.outputDir : outputDir // ignore: cast_nullable_to_non_nullable
as String,channels: null == channels ? _self.channels : channels // ignore: cast_nullable_to_non_nullable
as List<String>,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as PackStatus,progress: null == progress ? _self.progress : progress // ignore: cast_nullable_to_non_nullable
as double,currentChannel: freezed == currentChannel ? _self.currentChannel : currentChannel // ignore: cast_nullable_to_non_nullable
as String?,generatedFiles: null == generatedFiles ? _self.generatedFiles : generatedFiles // ignore: cast_nullable_to_non_nullable
as List<String>,errorMessage: freezed == errorMessage ? _self.errorMessage : errorMessage // ignore: cast_nullable_to_non_nullable
as String?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,completedAt: freezed == completedAt ? _self.completedAt : completedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [ChannelPackTask].
extension ChannelPackTaskPatterns on ChannelPackTask {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ChannelPackTask value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ChannelPackTask() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ChannelPackTask value)  $default,){
final _that = this;
switch (_that) {
case _ChannelPackTask():
return $default(_that);}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ChannelPackTask value)?  $default,){
final _that = this;
switch (_that) {
case _ChannelPackTask() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String apkPath,  String outputDir,  List<String> channels,  PackStatus status,  double progress,  String? currentChannel,  List<String> generatedFiles,  String? errorMessage,  DateTime createdAt,  DateTime? completedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ChannelPackTask() when $default != null:
return $default(_that.id,_that.apkPath,_that.outputDir,_that.channels,_that.status,_that.progress,_that.currentChannel,_that.generatedFiles,_that.errorMessage,_that.createdAt,_that.completedAt);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String apkPath,  String outputDir,  List<String> channels,  PackStatus status,  double progress,  String? currentChannel,  List<String> generatedFiles,  String? errorMessage,  DateTime createdAt,  DateTime? completedAt)  $default,) {final _that = this;
switch (_that) {
case _ChannelPackTask():
return $default(_that.id,_that.apkPath,_that.outputDir,_that.channels,_that.status,_that.progress,_that.currentChannel,_that.generatedFiles,_that.errorMessage,_that.createdAt,_that.completedAt);}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String apkPath,  String outputDir,  List<String> channels,  PackStatus status,  double progress,  String? currentChannel,  List<String> generatedFiles,  String? errorMessage,  DateTime createdAt,  DateTime? completedAt)?  $default,) {final _that = this;
switch (_that) {
case _ChannelPackTask() when $default != null:
return $default(_that.id,_that.apkPath,_that.outputDir,_that.channels,_that.status,_that.progress,_that.currentChannel,_that.generatedFiles,_that.errorMessage,_that.createdAt,_that.completedAt);case _:
  return null;

}
}

}

/// @nodoc


class _ChannelPackTask extends ChannelPackTask {
  const _ChannelPackTask({required this.id, required this.apkPath, required this.outputDir, required final  List<String> channels, this.status = PackStatus.idle, this.progress = 0.0, this.currentChannel, final  List<String> generatedFiles = const [], this.errorMessage, required this.createdAt, this.completedAt}): _channels = channels,_generatedFiles = generatedFiles,super._();
  

/// 任务 ID
@override final  String id;
/// 原始 APK 文件路径
@override final  String apkPath;
/// 输出目录
@override final  String outputDir;
/// 渠道列表
 final  List<String> _channels;
/// 渠道列表
@override List<String> get channels {
  if (_channels is EqualUnmodifiableListView) return _channels;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_channels);
}

/// 任务状态
@override@JsonKey() final  PackStatus status;
/// 当前进度 (0.0 - 1.0)
@override@JsonKey() final  double progress;
/// 当前正在处理的渠道
@override final  String? currentChannel;
/// 已生成的文件列表
 final  List<String> _generatedFiles;
/// 已生成的文件列表
@override@JsonKey() List<String> get generatedFiles {
  if (_generatedFiles is EqualUnmodifiableListView) return _generatedFiles;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_generatedFiles);
}

/// 错误信息
@override final  String? errorMessage;
/// 创建时间
@override final  DateTime createdAt;
/// 完成时间
@override final  DateTime? completedAt;

/// Create a copy of ChannelPackTask
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ChannelPackTaskCopyWith<_ChannelPackTask> get copyWith => __$ChannelPackTaskCopyWithImpl<_ChannelPackTask>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ChannelPackTask&&(identical(other.id, id) || other.id == id)&&(identical(other.apkPath, apkPath) || other.apkPath == apkPath)&&(identical(other.outputDir, outputDir) || other.outputDir == outputDir)&&const DeepCollectionEquality().equals(other._channels, _channels)&&(identical(other.status, status) || other.status == status)&&(identical(other.progress, progress) || other.progress == progress)&&(identical(other.currentChannel, currentChannel) || other.currentChannel == currentChannel)&&const DeepCollectionEquality().equals(other._generatedFiles, _generatedFiles)&&(identical(other.errorMessage, errorMessage) || other.errorMessage == errorMessage)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.completedAt, completedAt) || other.completedAt == completedAt));
}


@override
int get hashCode => Object.hash(runtimeType,id,apkPath,outputDir,const DeepCollectionEquality().hash(_channels),status,progress,currentChannel,const DeepCollectionEquality().hash(_generatedFiles),errorMessage,createdAt,completedAt);

@override
String toString() {
  return 'ChannelPackTask(id: $id, apkPath: $apkPath, outputDir: $outputDir, channels: $channels, status: $status, progress: $progress, currentChannel: $currentChannel, generatedFiles: $generatedFiles, errorMessage: $errorMessage, createdAt: $createdAt, completedAt: $completedAt)';
}


}

/// @nodoc
abstract mixin class _$ChannelPackTaskCopyWith<$Res> implements $ChannelPackTaskCopyWith<$Res> {
  factory _$ChannelPackTaskCopyWith(_ChannelPackTask value, $Res Function(_ChannelPackTask) _then) = __$ChannelPackTaskCopyWithImpl;
@override @useResult
$Res call({
 String id, String apkPath, String outputDir, List<String> channels, PackStatus status, double progress, String? currentChannel, List<String> generatedFiles, String? errorMessage, DateTime createdAt, DateTime? completedAt
});




}
/// @nodoc
class __$ChannelPackTaskCopyWithImpl<$Res>
    implements _$ChannelPackTaskCopyWith<$Res> {
  __$ChannelPackTaskCopyWithImpl(this._self, this._then);

  final _ChannelPackTask _self;
  final $Res Function(_ChannelPackTask) _then;

/// Create a copy of ChannelPackTask
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? apkPath = null,Object? outputDir = null,Object? channels = null,Object? status = null,Object? progress = null,Object? currentChannel = freezed,Object? generatedFiles = null,Object? errorMessage = freezed,Object? createdAt = null,Object? completedAt = freezed,}) {
  return _then(_ChannelPackTask(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,apkPath: null == apkPath ? _self.apkPath : apkPath // ignore: cast_nullable_to_non_nullable
as String,outputDir: null == outputDir ? _self.outputDir : outputDir // ignore: cast_nullable_to_non_nullable
as String,channels: null == channels ? _self._channels : channels // ignore: cast_nullable_to_non_nullable
as List<String>,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as PackStatus,progress: null == progress ? _self.progress : progress // ignore: cast_nullable_to_non_nullable
as double,currentChannel: freezed == currentChannel ? _self.currentChannel : currentChannel // ignore: cast_nullable_to_non_nullable
as String?,generatedFiles: null == generatedFiles ? _self._generatedFiles : generatedFiles // ignore: cast_nullable_to_non_nullable
as List<String>,errorMessage: freezed == errorMessage ? _self.errorMessage : errorMessage // ignore: cast_nullable_to_non_nullable
as String?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,completedAt: freezed == completedAt ? _self.completedAt : completedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on
