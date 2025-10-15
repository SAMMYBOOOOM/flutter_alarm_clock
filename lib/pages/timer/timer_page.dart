import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_alarm_clock_demo/data/theme_data.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class TimerPage extends StatefulWidget {
  const TimerPage({super.key});

  @override
  State createState() {
    return _TimerPageState();
  }
}

class _TimerPageState extends State<TimerPage> {
  Timer? _timer;
  bool _isRunning = false;
  bool _isCountingUp = false;
  Duration _duration = Duration(minutes: 5);
  Duration _remainingTime = Duration(minutes: 5);
  Duration _overtime = Duration.zero;

  // Notification plugin
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();

  @override
  void initState() {
    super.initState();
    _initializeNotifications();
  }

  Future<void> _initializeNotifications() async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
    AndroidNotificationDetails(
      'timer_channel',
      'Timer Notifications',
      channelDescription: 'Notifications for timer completion',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
    );

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: DarwinNotificationDetails(),
    );

    // Initialize notifications (this ensures the channel is created)
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
    >()
        ?.createNotificationChannel(
      const AndroidNotificationChannel(
        'timer_channel',
        'Timer Notifications',
        description: 'Notifications for timer completion',
        importance: Importance.max,
      ),
    );
  }

  void _startTimer() {
    setState(() {
      _isRunning = true;
    });

    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        if (!_isCountingUp) {
          // Count down phase
          if (_remainingTime.inSeconds > 0) {
            _remainingTime = _remainingTime - Duration(seconds: 1);
          } else {
            // Timer reached 0 - switch to count up automatically
            _onTimerComplete();
            // Don't cancel the timer - let it continue counting up
          }
        } else {
          // Count up phase (overtime)
          _overtime = _overtime + Duration(seconds: 1);
        }
      });
    });
  }

  void _onTimerComplete() {
    setState(() {
      _isCountingUp = true;
      // Keep _isRunning as true to continue counting up automatically
    });
    _showCompletionNotification();
  }

  Future<void> _showCompletionNotification() async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
    AndroidNotificationDetails(
      'timer_channel',
      'Timer Notifications',
      channelDescription: 'Notifications for timer completion',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
    );

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: DarwinNotificationDetails(),
    );

    await flutterLocalNotificationsPlugin.show(
      0,
      'Timer Completed!',
      'Your timer has finished counting down',
      platformChannelSpecifics,
    );
  }

  void _pauseTimer() {
    setState(() {
      _isRunning = false;
    });
    _timer?.cancel();
  }

  void _resetTimer() {
    setState(() {
      _isRunning = false;
      _isCountingUp = false;
      _remainingTime = _duration;
      _overtime = Duration.zero;
    });
    _timer?.cancel();
  }

  void _setDuration(Duration duration) {
    setState(() {
      _duration = duration;
      _remainingTime = duration;
      _isCountingUp = false;
      _overtime = Duration.zero;
    });
    _resetTimer();
  }

  void _showCustomTimeDialog() {
    int hours = _duration.inHours;
    int minutes = _duration.inMinutes.remainder(60);
    int seconds = _duration.inSeconds.remainder(60);

    // Create controllers for each wheel to set initial position
    FixedExtentScrollController hoursController = FixedExtentScrollController(initialItem: hours);
    FixedExtentScrollController minutesController = FixedExtentScrollController(initialItem: minutes);
    FixedExtentScrollController secondsController = FixedExtentScrollController(initialItem: seconds);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: CustomColors.menuBackgroundColor,
          title: Text(
            'Set Custom Time',
            style: TextStyle(
              color: CustomColors.primaryTextColor,
              fontFamily: 'avenir',
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildTimePickerColumn('Hours', hoursController, 0, 23, (value) {
                    hours = value;
                  }),
                  _buildTimePickerColumn('Minutes', minutesController, 0, 59, (value) {
                    minutes = value;
                  }),
                  _buildTimePickerColumn('Seconds', secondsController, 0, 59, (value) {
                    seconds = value;
                  }),
                ],
              ),
              SizedBox(height: 16),
              Text(
                'Selected: ${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
                style: TextStyle(
                  color: CustomColors.primaryTextColor,
                  fontFamily: 'avenir',
                  fontSize: 16,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: CustomColors.primaryTextColor,
                  fontFamily: 'avenir',
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                Duration newDuration = Duration(
                  hours: hours,
                  minutes: minutes,
                  seconds: seconds,
                );
                if (newDuration.inSeconds > 0) {
                  _setDuration(newDuration);
                } else {
                  // Show error if time is 0
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Please set a time greater than 0 seconds'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }
                Navigator.of(context).pop();
              },
              child: Text(
                'Set',
                style: TextStyle(
                  color: CustomColors.clockOutline,
                  fontFamily: 'avenir',
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTimePickerColumn(
      String label,
      FixedExtentScrollController controller,
      int min,
      int max,
      Function(int) onChanged,
      ) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            color: CustomColors.primaryTextColor,
            fontFamily: 'avenir',
          ),
        ),
        SizedBox(height: 8),
        Container(
          width: 70,
          height: 140,
          decoration: BoxDecoration(
            color: CustomColors.clockBG.withOpacity(0.5),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: CustomColors.clockOutline),
          ),
          child: ListWheelScrollView.useDelegate(
            controller: controller,
            itemExtent: 40,
            diameterRatio: 1.2,
            physics: FixedExtentScrollPhysics(),
            onSelectedItemChanged: (index) {
              onChanged(index + min);
            },
            childDelegate: ListWheelChildBuilderDelegate(
              childCount: max - min + 1,
              builder: (context, index) {
                final value = index + min;
                return Center(
                  child: Text(
                    value.toString().padLeft(2, '0'),
                    style: TextStyle(
                      color: CustomColors.primaryTextColor,
                      fontSize: 20,
                      fontFamily: 'avenir',
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));

    if (duration.inHours > 0) {
      return "${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
    } else {
      return "$twoDigitMinutes:$twoDigitSeconds";
    }
  }

  String _getDisplayTime() {
    if (_isCountingUp) {
      return "+${_formatDuration(_overtime)}";
    } else {
      return _formatDuration(_remainingTime);
    }
  }

  Color _getTimerColor() {
    if (_isCountingUp) {
      return Colors.orange;
    } else if (_remainingTime.inSeconds <= 10 && _remainingTime.inSeconds > 0) {
      return Colors.red;
    } else {
      return CustomColors.primaryTextColor;
    }
  }

  double _getProgress() {
    if (_isCountingUp) {
      return 0.0;
    } else {
      return 1.0 - (_remainingTime.inSeconds / _duration.inSeconds);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double progress = _getProgress();

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 32, vertical: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            "Timer",
            style: TextStyle(
              fontFamily: 'avenir',
              fontWeight: FontWeight.w700,
              color: CustomColors.primaryTextColor,
              fontSize: 24,
            ),
          ),
          SizedBox(height: 16),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Circular Progress Timer
                Expanded(
                  flex: 3,
                  child: Center(
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Progress background
                        Container(
                          width: 250,
                          height: 250,
                          child: CircularProgressIndicator(
                            value: progress,
                            strokeWidth: 8,
                            backgroundColor: CustomColors.clockBG.withOpacity(0.3),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              _isCountingUp
                                  ? Colors.orange
                                  : CustomColors.clockOutline,
                            ),
                          ),
                        ),
                        // Inner circle
                        Container(
                          width: 230,
                          height: 230,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: CustomColors.clockBG.withOpacity(0.5),
                          ),
                        ),
                        // Timer text
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _getDisplayTime(),
                              style: TextStyle(
                                fontFamily: 'avenir',
                                fontSize: 36,
                                fontWeight: FontWeight.w700,
                                color: _getTimerColor(),
                              ),
                            ),
                            if (_isCountingUp)
                              Text(
                                "Time's up!",
                                style: TextStyle(
                                  fontFamily: 'avenir',
                                  fontSize: 16,
                                  color: Colors.orange,
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // Preset Duration Buttons
                Expanded(
                  flex: 2,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildDurationButton(Duration(minutes: 1), "1 min"),
                          _buildDurationButton(Duration(minutes: 5), "5 min"),
                          _buildDurationButton(Duration(minutes: 10), "10 min"),
                        ],
                      ),
                      SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildDurationButton(Duration(minutes: 15), "15 min"),
                          _buildDurationButton(Duration(minutes: 30), "30 min"),
                          _buildCustomTimeButton(),
                        ],
                      ),
                    ],
                  ),
                ),

                // Control Buttons
                Expanded(
                  flex: 1,
                  child: Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        if (!_isRunning)
                          _buildControlButton(
                            Icons.play_arrow,
                            _isCountingUp ? "Resume" : "Start",
                            _startTimer,
                          )
                        else
                          _buildControlButton(
                            Icons.pause,
                            "Pause",
                            _pauseTimer,
                          ),

                        _buildControlButton(
                          Icons.refresh,
                          "Reset",
                          _resetTimer,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDurationButton(Duration duration, String label) {
    bool isSelected = _duration == duration && !_isCountingUp;
    return Column(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isSelected
                ? CustomColors.clockOutline
                : CustomColors.clockBG.withOpacity(0.5),
            border: Border.all(
              color: _isCountingUp ? Colors.grey : CustomColors.clockOutline,
              width: 2,
            ),
          ),
          child: IconButton(
            icon: Text(
              label.split(' ')[0],
              style: TextStyle(
                color: isSelected
                    ? CustomColors.pageBackgroundColor
                    : CustomColors.primaryTextColor,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
            onPressed: _isCountingUp ? null : () => _setDuration(duration),
          ),
        ),
        SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: _isCountingUp ? Colors.grey : CustomColors.primaryTextColor,
            fontFamily: 'avenir',
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildCustomTimeButton() {
    return Column(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: CustomColors.clockBG.withOpacity(0.5),
            border: Border.all(
              color: _isCountingUp ? Colors.grey : CustomColors.clockOutline,
              width: 2,
            ),
          ),
          child: IconButton(
            icon: Icon(
              Icons.schedule,
              color: _isCountingUp
                  ? Colors.grey
                  : CustomColors.primaryTextColor,
              size: 24,
            ),
            onPressed: _isCountingUp ? null : _showCustomTimeDialog,
          ),
        ),
        SizedBox(height: 4),
        Text(
          "Custom",
          style: TextStyle(
            color: _isCountingUp ? Colors.grey : CustomColors.primaryTextColor,
            fontFamily: 'avenir',
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildControlButton(
      IconData icon,
      String label,
      VoidCallback onPressed,
      ) {
    return Column(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: CustomColors.clockOutline,
          ),
          child: IconButton(
            icon: Icon(icon, size: 24, color: CustomColors.pageBackgroundColor),
            onPressed: onPressed,
          ),
        ),
        SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: CustomColors.primaryTextColor,
            fontFamily: 'avenir',
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}