import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_alarm_clock_demo/data/data.dart';
import 'package:flutter_alarm_clock_demo/data/enums.dart';
import 'package:flutter_alarm_clock_demo/data/theme_data.dart';
import 'package:flutter_alarm_clock_demo/data/models/menu_info.dart';
import 'package:flutter_alarm_clock_demo/pages/alarm/alarm_page.dart';
import 'package:flutter_alarm_clock_demo/pages/clock/clock_page.dart';
import 'package:flutter_alarm_clock_demo/pages/stopwatch/stopwatch_page.dart';
import 'package:flutter_alarm_clock_demo/pages/timer/timer_page.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class HomePage extends StatefulWidget {
  @override
  State createState() {
    return _HomePageState();
  }
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    var now = DateTime.now();
    var formattedTime = DateFormat("HH:mm").format(now);
    var formattedDate = DateFormat("EEE, d MMM").format(now);
    var timezoneString = now.timeZoneOffset.toString().split(".").first;
    var offsetSign = "";
    if (!timezoneString.startsWith("-")) {
      offsetSign = "+";
    }

    return Scaffold(
      backgroundColor: Color(0xFF2D2F41),
      body: Row(
        children: <Widget>[
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: menuItems
                .map((currentMenuInfo) => buildMenuButton(currentMenuInfo))
                .toList(),
          ),
          VerticalDivider(color: Colors.white54, width: 1),
          Expanded(
            child: Consumer<MenuInfo>(
              builder: (BuildContext context, MenuInfo value, Widget? child) {
                if (value.menuType == MenuType.clock) {
                  return ClockPage();
                } else if (value.menuType == MenuType.alarm) {
                  return AlarmPage();
                } else if (value.menuType == MenuType.timer) {
                  return TimerPage();
                } else if (value.menuType == MenuType.stopwatch) {
                  return StopwatchPage();
                }
                return Container();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget buildMenuButton(MenuInfo currentMenuInfo) {
    return Consumer<MenuInfo>(
      builder: (BuildContext context, MenuInfo value, Widget? child) {
        return TextButton(
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            backgroundColor: currentMenuInfo.menuType == value.menuType
                ? CustomColors.menuBackgroundColor
                : Colors.transparent,
          ),
          onPressed: () {
            var menuInfo = Provider.of<MenuInfo>(context, listen: false);
            menuInfo.updateMenu(currentMenuInfo);
          },
          child: Column(
            children: <Widget>[
              Image.asset(currentMenuInfo.imageSource ?? "", scale: 1.5),
              SizedBox(height: 16),
              Text(
                currentMenuInfo.title ?? "",
                style: TextStyle(
                  fontFamily: "avenir",
                  color: Colors.white,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
