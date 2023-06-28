import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import 'package:logger/logger.dart';

var logger = Logger();

/// 本地通知工具类
class SyLocalNotifyUtil {
  late FlutterLocalNotificationsPlugin localNotify;

  SyLocalNotifyUtil._() {
    localNotify = FlutterLocalNotificationsPlugin();
  }

  static final SyLocalNotifyUtil _instance = SyLocalNotifyUtil._();

  static SyLocalNotifyUtil get instance => _instance;

  final StreamController<String?> selectNotificationStream =
      StreamController<String?>.broadcast();

  /// 初始化本地通知库
  ///
  /// * [androidIcon] Android通知图标
  /// * [onClickNotify] 点击通知回调
  /// * [iosForegroundNotify] iOS在前台时发送通知的回调
  Future<void> initNotify({
    String? androidIcon,
  }) async {
    // Android配置
    var android = AndroidInitializationSettings(
      // icon
      androidIcon ?? '@mipmap/ic_launcher',
    );
    // iOS配置
    final DarwinInitializationSettings iOS = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
      onDidReceiveLocalNotification: onDidReceiveLocalNotification,
    );

    // 设置时区
    await _configureLocalTimeZone();
    // 初始化通知
    await localNotify
        .initialize(InitializationSettings(android: android, iOS: iOS),
            // 通知点击回调
            onDidReceiveNotificationResponse:
                (NotificationResponse notificationResponse) {
      logger.d(
          'onDidReceiveNotificationResponse--------${notificationResponse.notificationResponseType}');
      selectNotificationStream.add(notificationResponse.payload);
    }, onDidReceiveBackgroundNotificationResponse: notificationTapBackground);
  }

  /// You need to configure a top level or static method which will handle the action
  static notificationTapBackground(NotificationResponse notificationResponse) {
    logger.d('notification(${notificationResponse.id}) action tapped: '
        '${notificationResponse.actionId} with'
        ' payload: ${notificationResponse.payload}');
    if (notificationResponse.input?.isNotEmpty ?? false) {
      logger.d(
          'notification action tapped with input: ${notificationResponse.input}');
    }
  }

  void onDidReceiveLocalNotification(
      int id, String? title, String? body, String? payload) async {
    logger.d(
        'onDidReceiveLocalNotification-id===${id},title===${title},body===${body},payload===${payload}');
  }

  Future<void> _configureLocalTimeZone() async {
    if (kIsWeb || Platform.isLinux) {
      return;
    }
    tz.initializeTimeZones();
    final String? timeZoneName = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(timeZoneName!));
  }

  // 申请通知权限
  Future<bool> requestPermission() async {
    if (kIsWeb) return false;

    if (Platform.isAndroid) {
      return await localNotify
              .resolvePlatformSpecificImplementation<
                  AndroidFlutterLocalNotificationsPlugin>()
              ?.requestPermission() ??
          false;
    }
    if (Platform.isIOS) {
      return await localNotify
              .resolvePlatformSpecificImplementation<
                  IOSFlutterLocalNotificationsPlugin>()
              ?.requestPermissions(
                alert: true,
                badge: true,
                sound: true,
              ) ??
          false;
    }
    return false;
  }

  /// 显示一个本地通知
  /// * [id] 通知唯一标识,用来替换和关闭
  /// * [title] 标题
  /// * [body] 内容
  /// * [payload] 附带信息, 点击通知时会回调
  /// * [android] android通知配置
  /// * [iOS] iOS通知配置
  Future<void> show({
    int? id,
    String? title,
    String? body,
    String? payload,
    AndroidNotificationDetails? android,
    DarwinNotificationDetails? iOS,
  }) async {
    var detail = NotificationDetails(
      android: android ?? setAndroidNotify(),
      iOS: iOS,
    );
    await localNotify.show(
      id ?? _randomId(),
      title,
      body,
      detail,
      payload: payload,
    );
  }

  /// 创建通知渠道
  Future<void> createchannel({
    required AndroidNotificationChannel channel,
  }) async {
    await localNotify
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  /// 通知渠道配置
  AndroidNotificationChannel configChannel({
    required String channelId,
    required String channelName,
    String? description,
    Importance? importance,
    bool? playSound,
    bool? enableVibration,
  }) =>
      AndroidNotificationChannel(
        channelId,
        channelName,
        description: description,
        importance: importance ?? Importance.high,
        playSound: playSound ?? false,
        enableVibration: enableVibration ?? false,
      );

  /// 获取所有通知渠道
  Future<List<AndroidNotificationChannel>?> getNotificationChannels() async {
    List<AndroidNotificationChannel>? channels;
    try {
      channels = await localNotify
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()!
          .getNotificationChannels();
    } on PlatformException catch (error) {
      logger.d(
        'Error calling "getNotificationChannels"\n'
        'code: ${error.code}\n'
        'message: ${error.message}',
      );
    }
    return channels;
  }

  /// 指定时间通知
  /// * [scheduledDate] 发送通知的时间 TZDateTime.now(local).add(const Duration(seconds: 5))
  /// * [id] 通知唯一标识,用来替换和关闭
  /// * [title] 标题
  /// * [body] 内容
  /// * [payload] 附带信息, 点击通知时会回调
  /// * [android] android通知配置
  /// * [iOS] iOS通知配置
  /// * [matchDateTimeComponents] 时间的显示格式
  Future<void> delayedShow(
    tz.TZDateTime scheduledDate, {
    int? id,
    String? title,
    String? body,
    String? payload,
    AndroidNotificationDetails? android,
    DateTimeComponents? matchDateTimeComponents,
  }) async {
    var detail = NotificationDetails(
      android: android ?? setAndroidNotify(),
    );
    localNotify.zonedSchedule(
      id ?? _randomId(),
      title,
      body,
      scheduledDate,
      detail,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      androidAllowWhileIdle: true,
      payload: payload,
      matchDateTimeComponents: matchDateTimeComponents,
    );
  }

  /// 定期通知
  /// * [repeatInterval] 周期方式
  /// * [id] 通知唯一标识,用来替换和关闭
  /// * [title] 标题
  /// * [body] 内容
  /// * [payload] 附带信息, 点击通知时会回调
  /// * [android] android通知配置
  /// * [iOS] iOS通知配置
  Future<void> periodicallyShow(
    RepeatInterval repeatInterval, {
    int? id,
    String? title,
    String? body,
    String? payload,
    AndroidNotificationDetails? android,
  }) async {
    var detail = NotificationDetails(android: android);
    localNotify.periodicallyShow(
      id ?? _randomId(),
      title,
      body,
      repeatInterval,
      detail,
      androidAllowWhileIdle: true,
      payload: payload,
    );
  }

  int _randomId() => Random().nextInt(pow(2, 31).toInt());

  /// 关闭指定id的通知
  /// Android可用tag关闭
  Future<void> cancel(int id, {String? tag}) async {
    await localNotify.cancel(id, tag: tag);
  }

  /// 关闭所有通知
  Future<void> cancelAll() async {
    await localNotify.cancelAll();
  }

  /// 获取待显示的通知
  Future<List<PendingNotificationRequest>> getPendingNotify() =>
      localNotify.pendingNotificationRequests();

  /// 配置Android通知
  /// * [channelId] 通知分类id
  /// * [channelName] 通知分类名称
  /// * [channelDescription] 通知分类描述
  /// * [icon] 通知图标, 默认使用[initNotify]中的图标
  /// * [importance] 重要级别
  /// * [priority] 优先级
  /// * [styleInformation] 富文本通知
  /// * [playSound] 是否播放声音
  /// * [sound] 音频文件
  /// * [enableVibration] 是否震动
  /// * [groupKey] 通知所属组
  /// * [setAsGroupSummary] 是否用作分组摘要
  /// * [groupAlertBehavior] 此分组的通知方式 震动声音\震动\静默
  /// * [autoCancel] 点击关闭此通知
  /// * [ongoing] 是否'正在运行'特殊通知
  /// * [color]
  /// * [largeIcon] 大图
  /// * [showWhen] 是否显示时间
  /// * [when] 时间戳
  /// * [usesChronometer] 秒表计时
  /// * [channelShowBadge] APP图标增加标记
  /// * [progressEnable] 是否显示进度
  /// * [maxProgress] 进度最大值
  /// * [progress] 进度当前值
  /// * [autoProgress] 是否显示自动滚动进度条
  AndroidNotificationDetails setAndroidNotify({
    String? channelId,
    String? channelName,
    String? channelDes,
    String? icon,
    Importance? importance,
    Priority? priority,
    BigPictureStyleInformation? styleInformation,
    bool playSound = true,
    String? sound,
    bool enableVibration = true,
    String? groupKey,
    bool setAsGroupSummary = false,
    GroupAlertBehavior groupAlertBehavior = GroupAlertBehavior.all,
    bool autoCancel = true,
    bool ongoing = false,
    Color? color,
    AndroidBitmap<Object>? largeIcon,
    bool showWhen = true,
    int? when,
    bool usesChronometer = false,
    bool channelShowBadge = true,
    bool progressEnable = false,
    int maxProgress = 0,
    int progress = 0,
    bool autoProgress = false,
  }) =>
      AndroidNotificationDetails(
        channelId ?? 'channelId',
        channelName ?? 'channelName',
        channelDescription: channelDes ?? '',
        icon: icon,
        importance: importance ?? Importance.high,
        priority: priority ?? Priority.high,
        styleInformation: styleInformation,
        playSound: playSound,
        sound:
            sound == null ? null : RawResourceAndroidNotificationSound(sound),
        enableVibration: enableVibration,
        groupKey: groupKey,
        setAsGroupSummary: setAsGroupSummary,
        groupAlertBehavior: groupAlertBehavior,
        autoCancel: autoCancel,
        ongoing: ongoing,
        color: color,
        largeIcon: largeIcon,
        showWhen: showWhen,
        when: when,
        usesChronometer: usesChronometer,
        channelShowBadge: channelShowBadge,
        showProgress: autoProgress ? true : progressEnable,
        maxProgress: maxProgress,
        progress: progress,
        indeterminate: autoProgress,
        visibility: NotificationVisibility.public,
      );

  /// 配置iOS通知
  DarwinNotificationDetails setIOSNotify({
    String? sound,
    bool presentSound = true,
  }) =>
      DarwinNotificationDetails(sound: sound, presentSound: presentSound);

  /// 是否开启通知
  Future<bool> areAndroidEnabled() async {
    final bool? areEnabled = await localNotify
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.areNotificationsEnabled();
    return areEnabled ?? false;
  }
}

class ReceivedNotification {
  ReceivedNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.payload,
  });

  final int id;
  final String? title;
  final String? body;
  final String? payload;
}
