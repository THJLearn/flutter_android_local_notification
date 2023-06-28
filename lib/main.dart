import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_my_notification_application/local_notify_util.dart';
import 'package:flutter_ringtone_player/flutter_ringtone_player.dart';
import 'package:vibration/vibration.dart';
import 'package:audio_session/audio_session.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // TRY THIS: Try running your application with "flutter run". You'll see
        // the application has a blue toolbar. Then, without quitting the app,
        // try changing the seedColor in the colorScheme below to Colors.green
        // and then invoke "hot reload" (save your changes or press the "hot
        // reload" button in a Flutter-supported IDE, or press "r" if you used
        // the command line to start the app).
        //
        // Notice that the counter didn't reset back to zero; the application
        // state is not lost during the reload. To reset the state, use hot
        // restart instead.
        //
        // This works for code too, not just values: Most code changes can be
        // tested with just a hot reload.
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

const String CHANNEL_ID = "channel_ID_0000";
const String CHANNEL_ID2 = "channel_ID_2222";
const String CHANNEL_ID3 = "channel_ID_3333";

class _MyHomePageState extends State<MyHomePage> {
  String CHANNEL_Name1 = "系统通道";
  String CHANNEL_Name2 = "自定义铃声通道";
  String CHANNEL_Name3 = "震动通道";
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _initPushChanel();
  }

  void _incrementCounter() {}

  _initPushChanel() async {
    // // 初始化本地通知
    await SyLocalNotifyUtil.instance.initNotify();
    // // 申请通知权限
    await SyLocalNotifyUtil.instance.requestPermission();

    _initChannel1();
    _initChannel2();
    _initChannel3();
  }

  _initChannel1() {
    SyLocalNotifyUtil.instance.createchannel(
      channel: SyLocalNotifyUtil.instance
          .configChannel(channelId: CHANNEL_ID, channelName: CHANNEL_Name1),
    );
  }

  _initChannel2() {
    SyLocalNotifyUtil.instance.createchannel(
      channel: SyLocalNotifyUtil.instance
          .configChannel(channelId: CHANNEL_ID2, channelName: CHANNEL_Name2),
    );
  }

  _initChannel3() {
    SyLocalNotifyUtil.instance.createchannel(
      channel: SyLocalNotifyUtil.instance
          .configChannel(channelId: CHANNEL_ID3, channelName: CHANNEL_Name3),
    );
  }

  _pushNotificaton1() async {
    bool areAndroidEnabled =
        await SyLocalNotifyUtil.instance.areAndroidEnabled();
    if (!areAndroidEnabled) {
      _showAndroidCanNotPush();
      return;
    }
    SyLocalNotifyUtil.instance.show(
      title: '11111111不是不俗不俗吧',
      body: 'nwiefneifnwiefnewinfwenifweninefnife',
      android: SyLocalNotifyUtil.instance.setAndroidNotify(
        channelId: CHANNEL_ID,
        channelName: CHANNEL_Name1,
        channelDes: '',
        playSound: false,
        enableVibration: false,
      ),
    );
    _handleCustomPushSoundAndVibrate(CHANNEL_ID);
  }

  _pushNotificaton2() async {
    bool areAndroidEnabled =
        await SyLocalNotifyUtil.instance.areAndroidEnabled();
    if (!areAndroidEnabled) {
      _showAndroidCanNotPush();
      return;
    }
    SyLocalNotifyUtil.instance.show(
      title: '2222自定义11111111不是不俗不俗吧',
      body: '自定义铃声nwiefneifnwiefnewinfwenifweninefnife',
      android: SyLocalNotifyUtil.instance.setAndroidNotify(
        channelId: CHANNEL_ID2,
        channelName: CHANNEL_Name2,
        channelDes: '',
        playSound: false,
        enableVibration: false,
      ),
    );

    _handleCustomPushSoundAndVibrate(CHANNEL_ID2);
  }

  _pushNotificaton3() async {
    bool areAndroidEnabled =
        await SyLocalNotifyUtil.instance.areAndroidEnabled();
    if (!areAndroidEnabled) {
      _showAndroidCanNotPush();
      return;
    }
    SyLocalNotifyUtil.instance.show(
      title: '333333自定义11111111不是不俗不俗吧',
      body: '自定义铃声nwiefneifnwiefnewinfwenifweninefnife',
      android: SyLocalNotifyUtil.instance.setAndroidNotify(
        channelId: CHANNEL_ID3,
        channelName: CHANNEL_Name3,
        channelDes: '',
        playSound: false,
        enableVibration: false,
      ),
    );
    _handleCustomPushSoundAndVibrate(CHANNEL_ID3);
    // final List<AndroidNotificationChannel>? channels =
    //     await SyLocalNotifyUtil.instance.getNotificationChannels();
    // try {
    //   AndroidNotificationChannel? channel3 =
    //       channels?.firstWhere((element) => element.id == CHANNEL_ID3);
    //   if (channel3 == null) {
    //     _playNotificationRingtone();
    //     return;
    //   }

    //   _playNotificationUri(channel3.sound?.sound ?? '');
    // } catch (e) {
    //   _playNotificationRingtone();
    // }
  }

  _handleCustomPushSoundAndVibrate(String channelId) async {
    AndroidNotificationChannel? channel = await _getChannelWithId(channelId);
    if (channel == null) return;
    if (channel.importance == Importance.unspecified) {
      _showAndroidCanNotPush(content: '推送通知通道关闭');
      return;
    }
    final sound = channel.sound?.sound ?? "";
    final channelEnableVibration = channel.enableVibration;
    if (channelId == CHANNEL_ID) {
      if (sound.isEmpty) {
        _playNotificationRingtone(channelEnableVibration);
      } else {
        if (channelEnableVibration == false) {
          // 跟随系统如果渠道有声音 只震动
          Vibration.vibrate();
        }
      }
      return;
    }
    if (channelId == CHANNEL_ID2) {
      if (sound.isEmpty) {
        _playNotificationCustomRingtone();
      } else {
        if (channelEnableVibration == false) {
          _notificationRingtoneAddBobrate();
        }
      }

      return;
    }

    if (channelId == CHANNEL_ID3 && channelEnableVibration == false) {
      // 执行震动 渠道3 只震动
      Vibration.vibrate();
    }
  }

  Future<AndroidNotificationChannel?> _getChannelWithId(
      String channelId) async {
    final List<AndroidNotificationChannel>? channels =
        await SyLocalNotifyUtil.instance.getNotificationChannels();
    try {
      AndroidNotificationChannel? channel =
          channels?.firstWhere((element) => element.id == channelId);
      return channel;
    } catch (e) {
      return null;
    }
  }

  _playNotificationRingtone(bool channelEnableVibration) async {
    final vibration = await _notificationRingtoneAddBobrate();
    FlutterRingtonePlayer.playNotification();

    /// 说明提示音为0或者震动静音模式已经震动
    if (vibration) return;

    /// 说明渠道有震动
    if (channelEnableVibration) return;
    Vibration.vibrate();
  }

  _playNotificationCustomRingtone() async {
    await _notificationRingtoneAddBobrate();
    FlutterRingtonePlayer.play(fromAsset: "assets/audio/high_alert.mp3");
  }

  /// 如果系统声音为零或者震动静音模式会震动就不需要再次震动
  Future<bool> _notificationRingtoneAddBobrate() async {
    try {
      AndroidRingerMode mode = await AndroidAudioManager().getRingerMode();
      if (mode != AndroidRingerMode.normal) {
        // 静音或者震动模式 执行震动
        Vibration.vibrate();
        return true;
      } else {
        int volume = await AndroidAudioManager()
            .getStreamVolume(AndroidStreamType.notification);
        if (volume == 0) {
          // 通知声音为0震动模式 执行震动
          Vibration.vibrate();
          return true;
        }
      }
      return false;
    } catch (e) {
      logger.d('获取模式失败');
      return false;
    }
  }

  _showAndroidCanNotPush(
      {String content = "Notifications are NOT enabled"}) async {
    await showDialog<void>(
        context: context,
        builder: (BuildContext context) => AlertDialog(
              content: Text(content),
              actions: <Widget>[
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('OK'),
                ),
              ],
            ));
  }

  Future<void> _getNotificationChannels() async {
    final Widget notificationChannelsDialogContent =
        await _getNotificationChannelsDialogContent();
    // ignore: use_build_context_synchronously
    await showDialog<void>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        content: notificationChannelsDialogContent,
        actions: <Widget>[
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<Widget> _getNotificationChannelsDialogContent() async {
    final List<AndroidNotificationChannel>? channels =
        await SyLocalNotifyUtil.instance.getNotificationChannels();
    return SizedBox(
      width: double.maxFinite,
      child: ListView(
        children: <Widget>[
          const Text(
            'Notifications Channels',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const Divider(color: Colors.black),
          if (channels?.isEmpty ?? true)
            const Text('No notification channels')
          else
            for (AndroidNotificationChannel channel in channels!)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text('id: ${channel.id}\n'
                      'name: ${channel.name}\n'
                      'description: ${channel.description}\n'
                      'groupId: ${channel.groupId}\n'
                      'importance: ${channel.importance.value}\n'
                      'playSound: ${channel.playSound}\n'
                      'sound: ${channel.sound?.sound}\n'
                      'enableVibration: ${channel.enableVibration}\n'
                      'vibrationPattern: ${channel.vibrationPattern}\n'
                      'showBadge: ${channel.showBadge}\n'
                      'enableLights: ${channel.enableLights}\n'
                      'ledColor: ${channel.ledColor}\n'),
                  const Divider(color: Colors.black),
                ],
              ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        // TRY THIS: Try changing the color here to a specific color (to
        // Colors.amber, perhaps?) and trigger a hot reload to see the AppBar
        // change color while the other colors stay the same.
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body: Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            // InkWell(
            //   onTap: () => _initPushChanel(),
            //   child: Container(
            //     padding:
            //         const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            //     color: Colors.blue,
            //     child: const Center(
            //       child: Text('初始化push通道'),
            //     ),
            //   ),
            // ),
            // const SizedBox(height: 20),
            InkWell(
              onTap: () => _getNotificationChannels(),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                color: Colors.blue,
                child: const Center(
                  child: Text('获取所有渠道'),
                ),
              ),
            ),
            const SizedBox(height: 20),
            InkWell(
              onTap: () => _pushNotificaton1(),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                color: Colors.blue,
                child: const Center(
                  child: Text('跟随系统'),
                ),
              ),
            ),
            const SizedBox(height: 20),
            InkWell(
              onTap: () => _pushNotificaton2(),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                color: Colors.blue,
                child: const Center(
                  child: Text('自定义铃声'),
                ),
              ),
            ),
            const SizedBox(height: 20),
            InkWell(
              onTap: () => _pushNotificaton3(),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                color: Colors.blue,
                child: const Center(
                  child: Text('震动'),
                ),
              ),
            ),
            const SizedBox(height: 20),
            InkWell(
              onTap: () => _playNotificationRingtone(false),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                color: Colors.blue,
                child: const Center(
                  child: Text('播放系统铃声'),
                ),
              ),
            )
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
