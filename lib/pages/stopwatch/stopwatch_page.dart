import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_alarm_clock_demo/data/theme_data.dart';

class StopwatchPage extends StatefulWidget {
  @override
  State createState() {
    return _StopwatchPageState();
  }
}

class _StopwatchPageState extends State<StopwatchPage> {
  Stopwatch _stopwatch = Stopwatch();
  Duration _elapsedTime = Duration.zero;
  List<Duration> _laps = [];
  bool _isRunning = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
  }

  void _updateTimer() {
    if (mounted) {
      setState(() {
        _elapsedTime = _stopwatch.elapsed;
      });
    }
  }

  void _startStopwatch() {
    setState(() {
      _isRunning = true;
      _stopwatch.start();
    });
    // Use Timer.periodic for more precise timing
    _timer = Timer.periodic(Duration(milliseconds: 10), (timer) {
      _updateTimer();
    });
  }

  void _pauseStopwatch() {
    setState(() {
      _isRunning = false;
      _stopwatch.stop();
    });
    _timer?.cancel();
    _timer = null;
  }

  void _resetStopwatch() {
    // Cancel timer first to prevent any updates during reset
    _timer?.cancel();
    _timer = null;

    setState(() {
      _isRunning = false;
      _stopwatch.reset();
      _elapsedTime = Duration.zero; // Force set to zero
      _laps.clear();
    });
  }

  void _recordLap() {
    if (_isRunning) {
      setState(() {
        _laps.insert(0, _stopwatch.elapsed);
      });
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    String twoDigitMilliseconds = twoDigits((duration.inMilliseconds.remainder(1000) / 10).floor());
    return "$twoDigitMinutes:$twoDigitSeconds.$twoDigitMilliseconds";
  }

  String _formatLapTime(int index) {
    if (index == 0) {
      return _formatDuration(_laps[index]);
    } else {
      Duration lapTime = _laps[index] - _laps[index - 1];
      return _formatDuration(lapTime);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 32, vertical: 32), // Reduced padding
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            "Stopwatch",
            style: TextStyle(
              fontFamily: 'avenir',
              fontWeight: FontWeight.w700,
              color: CustomColors.primaryTextColor,
              fontSize: 24,
            ),
          ),
          SizedBox(height: 16), // Reduced spacing
          Expanded(
            child: Column(
              children: [
                // Time Display - Made smaller
                Expanded(
                  flex: 3,
                  child: Center(
                    child: Container(
                      width: 250, // Reduced size
                      height: 250,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: CustomColors.clockBG.withValues(alpha: 0.5),
                        border: Border.all(
                          color: CustomColors.clockOutline,
                          width: 4,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          _formatDuration(_elapsedTime),
                          style: TextStyle(
                            fontFamily: 'avenir',
                            fontSize: 32, // Reduced font size
                            fontWeight: FontWeight.w700,
                            color: CustomColors.primaryTextColor,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 20), // Reduced spacing

                // Control Buttons
                Expanded(
                  flex: 1,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      if (!_isRunning)
                        _buildControlButton(Icons.play_arrow, "Start", _startStopwatch)
                      else
                        _buildControlButton(Icons.pause, "Pause", _pauseStopwatch),

                      _buildControlButton(Icons.flag, "Lap", _recordLap, isEnabled: _isRunning),

                      _buildControlButton(Icons.refresh, "Reset", _resetStopwatch),
                    ],
                  ),
                ),
                SizedBox(height: 20), // Reduced spacing

                // Laps List
                Expanded(
                  flex: 3,
                  child: _laps.isEmpty
                      ? Center(
                    child: Text(
                      "No laps recorded",
                      style: TextStyle(
                        color: CustomColors.primaryTextColor.withValues(alpha: 0.5),
                        fontFamily: 'avenir',
                        fontSize: 16, // Reduced font size
                      ),
                    ),
                  )
                      : ListView.builder(
                    itemCount: _laps.length,
                    itemBuilder: (context, index) {
                      return Container(
                        margin: EdgeInsets.symmetric(vertical: 4),
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8), // Reduced padding
                        decoration: BoxDecoration(
                          color: CustomColors.clockBG.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: CustomColors.clockOutline.withValues(alpha: 0.5),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Lap ${_laps.length - index}",
                              style: TextStyle(
                                color: CustomColors.primaryTextColor,
                                fontFamily: 'avenir',
                                fontSize: 14, // Reduced font size
                              ),
                            ),
                            Text(
                              _formatLapTime(index),
                              style: TextStyle(
                                color: CustomColors.primaryTextColor,
                                fontFamily: 'avenir',
                                fontSize: 16, // Reduced font size
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton(IconData icon, String label, VoidCallback onPressed, {bool isEnabled = true}) {
    return Column(
      children: [
        Container(
          width: 60, // Reduced size
          height: 60,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isEnabled ? CustomColors.clockOutline : CustomColors.clockOutline.withValues(alpha: 0.3),
          ),
          child: IconButton(
            icon: Icon(icon, size: 24, color: CustomColors.pageBackgroundColor), // Reduced icon size
            onPressed: isEnabled ? onPressed : null,
          ),
        ),
        SizedBox(height: 4), // Reduced spacing
        Text(
          label,
          style: TextStyle(
            color: isEnabled ? CustomColors.primaryTextColor : CustomColors.primaryTextColor.withValues(alpha: 0.5),
            fontFamily: 'avenir',
            fontSize: 12, // Reduced font size
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _stopwatch.stop();
    super.dispose();
  }
}