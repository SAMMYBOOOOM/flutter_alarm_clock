import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:flutter_alarm_clock_demo/alarm_helper.dart';
import 'package:flutter_alarm_clock_demo/data/models/alarm_info.dart';
import 'package:flutter_alarm_clock_demo/data/theme_data.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/intl.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class AlarmPage extends StatefulWidget {
  @override
  State createState() {
    return _AlarmPageState();
  }
}

class _AlarmPageState extends State<AlarmPage> {
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  DateTime? _alarmTime;
  late String _alarmTimeString;
  bool _isRepeatSelected = false;
  AlarmHelper _alarmHelper = AlarmHelper();
  Future<List<AlarmInfo>>? _alarms;
  List<AlarmInfo>? _currentAlarms;

  @override
  void initState() {
    _alarmTime = DateTime.now();
    _alarmTimeString = DateFormat('HH:mm').format(_alarmTime!);
    loadAlarms();
    _alarmHelper.initializeDatabase().then((value) {
      print("------database initialized");
      loadAlarms();
    });
    init();
    super.initState();
  }

  void loadAlarms() {
    _alarms = _alarmHelper.getAlarms();
    _alarms!.then((alarms) {
      if (mounted) {
        setState(() {
          _currentAlarms = alarms;
        });
      }
    });
  }

  Future<void> init() async {
    // Initialize timezone
    _configureLocalTimeZone();

    const androidSettings = AndroidInitializationSettings("notification");
    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );
    const InitializationSettings initializationSettings =
        InitializationSettings(android: androidSettings, iOS: iosSettings);

    await flutterLocalNotificationsPlugin.initialize(initializationSettings);

    // Create notification channel
    await _createNotificationChannel();

    // Request permission
    await _requestNotificationPermission();
  }

  void _configureLocalTimeZone() {
    tz.initializeTimeZones();
    // For simplicity, use a fixed timezone. You can make this dynamic if needed.
    var location = tz.getLocation('Asia/Taipei');
    tz.setLocalLocation(location);
  }

  Future<void> _createNotificationChannel() async {
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'channel_id',
      'Alarm Channel',
      description: 'Channel for Alarm notifications',
      importance: Importance.max,
      enableVibration: true,
      playSound: true,
    );

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(channel);
  }

  Future<void> _requestNotificationPermission() async {
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();
  }

  void _showAddAlarmModal() {
    showModalBottomSheet(
      useRootNavigator: true,
      context: context,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Set Alarm',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 20),
                  TextButton(
                    onPressed: () async {
                      var selectedTime = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.now(),
                      );
                      if (selectedTime != null) {
                        final now = DateTime.now();
                        var selectedDateTime = DateTime(
                          now.year,
                          now.month,
                          now.day,
                          selectedTime.hour,
                          selectedTime.minute,
                        );
                        _alarmTime = selectedDateTime;
                        setModalState(() {
                          _alarmTimeString = DateFormat(
                            'HH:mm',
                          ).format(selectedDateTime);
                        });
                      }
                    },
                    child: Text(
                      _alarmTimeString,
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                  ListTile(
                    title: Text('Repeat Daily'),
                    trailing: Switch(
                      onChanged: (value) {
                        setModalState(() {
                          _isRepeatSelected = value;
                        });
                      },
                      value: _isRepeatSelected,
                    ),
                  ),
                  ListTile(
                    title: Text('Alarm Sound'),
                    subtitle: Text('Default Sound'),
                    trailing: Icon(Icons.arrow_forward_ios),
                  ),
                  ListTile(
                    title: Text('Alarm Label'),
                    subtitle: Text('Alarm'),
                    trailing: Icon(Icons.arrow_forward_ios),
                  ),
                  SizedBox(height: 20),
                  FloatingActionButton.extended(
                    onPressed: () {
                      onSaveAlarm(_isRepeatSelected);
                    },
                    icon: Icon(Icons.alarm),
                    label: Text('Save Alarm'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void scheduleAlarm(
    DateTime scheduledNotificationDateTime,
    AlarmInfo alarmInfo, {
    required bool isRepeating,
  }) async {
    var androidPlatformChannelSpecifics = AndroidNotificationDetails(
      'channel_id',
      'Alarm Channel',
      channelDescription: 'Channel for Alarm notification',
      icon: 'notification',
      sound: RawResourceAndroidNotificationSound('a_long_cold_sting'),
      largeIcon: DrawableResourceAndroidBitmap('codex_logo'),
      importance: Importance.max,
      priority: Priority.high,
    );

    var iOSPlatformChannelSpecifics = DarwinNotificationDetails(
      sound: 'a_long_cold_sting.wav',
    );

    var platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
    );

    if (isRepeating) {
      await flutterLocalNotificationsPlugin.zonedSchedule(
        alarmInfo.id ?? 0,
        'Alarm',
        alarmInfo.title,
        tz.TZDateTime.from(scheduledNotificationDateTime, tz.local),
        platformChannelSpecifics,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    } else {
      await flutterLocalNotificationsPlugin.zonedSchedule(
        alarmInfo.id ?? 0,
        'Alarm',
        alarmInfo.title,
        tz.TZDateTime.from(scheduledNotificationDateTime, tz.local),
        platformChannelSpecifics,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
    }
  }

  void onSaveAlarm(bool _isRepeating) {
    DateTime? scheduleAlarmDateTime;
    if (_alarmTime!.isAfter(DateTime.now())) {
      scheduleAlarmDateTime = _alarmTime;
    } else {
      scheduleAlarmDateTime = _alarmTime!.add(Duration(days: 1));
    }

    var alarmInfo = AlarmInfo(
      alarmDateTime: scheduleAlarmDateTime,
      gradientColorIndex: _currentAlarms?.length ?? 0,
      title: 'Alarm',
      isPending: 1,
    );

    _alarmHelper.insertAlarm(alarmInfo);

    if (scheduleAlarmDateTime != null) {
      scheduleAlarm(
        scheduleAlarmDateTime,
        alarmInfo,
        isRepeating: _isRepeating,
      );
    }

    Navigator.pop(context);
    loadAlarms();

    // Show confirmation
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Alarm set for ${DateFormat('HH:mm').format(scheduleAlarmDateTime!)}',
        ),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void deleteAlarm(int? id) {
    if (id != null) {
      _alarmHelper.delete(id).then((_) {
        // Cancel the scheduled notification
        flutterLocalNotificationsPlugin.cancel(id);
        loadAlarms();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Alarm deleted'),
            duration: Duration(seconds: 2),
          ),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 32, vertical: 64),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            "Alarm",
            style: TextStyle(
              fontFamily: 'avenir',
              fontWeight: FontWeight.w700,
              color: CustomColors.primaryTextColor,
              fontSize: 24,
            ),
          ),
          SizedBox(height: 20),
          Expanded(
            child: FutureBuilder<List<AlarmInfo>>(
              future: _alarms,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      "Error loading alarms",
                      style: TextStyle(color: Colors.white),
                    ),
                  );
                } else if (snapshot.hasData) {
                  final alarms = snapshot.data!;
                  _currentAlarms = alarms;

                  return Column(
                    children: [
                      if (alarms.isNotEmpty)
                        Expanded(
                          child: ListView.builder(
                            itemCount: alarms.length,
                            itemBuilder: (context, index) {
                              final alarm = alarms[index];
                              var alarmTime = DateFormat(
                                'hh:mm aa',
                              ).format(alarm.alarmDateTime!);
                              var gradientColor = GradientTemplate
                                  .gradientTemplate[alarm.gradientColorIndex! %
                                      GradientTemplate.gradientTemplate.length]
                                  .colors;

                              return Container(
                                margin: const EdgeInsets.only(bottom: 16),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: gradientColor,
                                    begin: Alignment.centerLeft,
                                    end: Alignment.centerRight,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: gradientColor.last.withValues(
                                        alpha: 0.4,
                                      ),
                                      blurRadius: 8,
                                      spreadRadius: 2,
                                      offset: Offset(4, 4),
                                    ),
                                  ],
                                  borderRadius: BorderRadius.all(
                                    Radius.circular(24),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: <Widget>[
                                        Row(
                                          children: <Widget>[
                                            Icon(
                                              Icons.label,
                                              color: Colors.white,
                                              size: 24,
                                            ),
                                            SizedBox(width: 8),
                                            Text(
                                              alarm.title ?? 'Alarm',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontFamily: 'avenir',
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                        Switch(
                                          onChanged: (bool value) {
                                            // TODO: Implement toggle functionality
                                          },
                                          value: alarm.isPending == 1,
                                          activeThumbColor: Colors.white,
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      'Mon-Fri',
                                      style: TextStyle(
                                        color: Colors.white.withValues(
                                          alpha: 0.8,
                                        ),
                                        fontFamily: 'avenir',
                                      ),
                                    ),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: <Widget>[
                                        Text(
                                          alarmTime,
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontFamily: 'avenir',
                                            fontSize: 24,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        IconButton(
                                          icon: Icon(Icons.delete),
                                          color: Colors.white,
                                          onPressed: () {
                                            deleteAlarm(alarm.id);
                                          },
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        )
                      else
                        Expanded(
                          child: Center(
                            child: Text(
                              "No alarms set",
                              style: TextStyle(
                                color: Colors.white54,
                                fontSize: 18,
                              ),
                            ),
                          ),
                        ),

                      // Add Alarm Button
                      DottedBorder(
                        options: RoundedRectDottedBorderOptions(
                          strokeWidth: 2,
                          color: CustomColors.clockOutline,
                          radius: Radius.circular(16),
                          dashPattern: [5, 4],
                        ),
                        child: Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: CustomColors.clockBG.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.all(Radius.circular(16)),
                          ),
                          child: MaterialButton(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 32,
                              vertical: 20,
                            ),
                            onPressed: _showAddAlarmModal,
                            child: Column(
                              children: <Widget>[
                                Icon(
                                  Icons.add_alarm,
                                  color: Colors.white,
                                  size: 40,
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'Add Alarm',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontFamily: 'avenir',
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                } else {
                  return Center(
                    child: Text(
                      "No alarms found",
                      style: TextStyle(color: Colors.white),
                    ),
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
