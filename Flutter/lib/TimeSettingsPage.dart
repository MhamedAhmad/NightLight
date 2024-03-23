import 'dart:math';

import 'package:flutter/material.dart';
import 'package:nightlight/ColorsPages/SleepColorPage.dart';
import 'package:nightlight/ColorsPages/WakeColorPage.dart';
import 'HomePage.dart';
import 'package:provider/provider.dart'; // Import provider package
import 'package:percent_indicator/percent_indicator.dart'; // Import the package
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'package:widget_zoom/widget_zoom.dart';



class TimeSettingsPage extends StatefulWidget {
  TimeSettingsPage(this.c_uid, {Key? key});

  late String c_uid;
  TimeOfDay? _startTime = TimeOfDay.now();
  TimeOfDay? _endTime = TimeOfDay.now();
  int delayTime = 0;
  int transitionTime = 0;
  int fadeOut = 0;
  int fadeIn = 0;
  bool isLoading = true;
  String loadingMessage = 'Loading Time Settings...';

  @override
  State<TimeSettingsPage> createState() => _TimeSettingsPageState();
}



class _TimeSettingsPageState extends State<TimeSettingsPage> {
  double _progress = 0.0;
  late Timer _timer;


  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        _progress = _calculateProgress();
      });
    });
  }


  @override
  void initState() {
    super.initState();
    _loadTimeSettings();
    //_updateProgressAutomatically();
    _startTimer();
  }

  void _updateProgressAutomatically() {
    Future.delayed(Duration(seconds: 1), () {
      _progress = _calculateProgress();
      _updateProgressAutomatically();
    });
  }

  bool get _isFadingIn {
    DateTime now = DateTime.now();
    DateTime startTime = DateTime(
        now.year, now.month, now.day, widget._startTime!.hour,
        widget._startTime!.minute).subtract(Duration(minutes: widget.fadeIn));
    DateTime fadeInEndTime = DateTime(
        now.year, now.month, now.day, widget._startTime!.hour,
        widget._startTime!.minute);
    if(!now.isBefore(fadeInEndTime))
      now = now.subtract(Duration(days: 1));
    return now.isAfter(startTime);
  }

  bool get _isNightMode {
    DateTime now = DateTime.now();
    DateTime startTime = DateTime(
        now.year, now.month, now.day, widget._startTime!.hour,
        widget._startTime!.minute);
    DateTime tranistion = DateTime(
        now.year, now.month, now.day, widget._endTime!.hour,
        widget._endTime!.minute).subtract(Duration(minutes: widget.transitionTime));
    if(!tranistion.isAfter(startTime))
      tranistion = tranistion.add(Duration(days: 1));
    if(!now.isAfter(startTime))
      now = now.add(Duration(days: 1));
    return now.isBefore(tranistion);
  }

  bool get _isTransitioning {
    DateTime now = DateTime.now();
    DateTime endTime = DateTime(
        now.year, now.month, now.day, widget._endTime!.hour,
        widget._endTime!.minute);
    DateTime tranistion = DateTime(
        now.year, now.month, now.day, widget._endTime!.hour,
        widget._endTime!.minute).subtract(Duration(minutes: widget.transitionTime));
    if(!now.isBefore(endTime))
      now = now.subtract(Duration(days: 1));
    return now.isAfter(tranistion);
  }

  bool get _isFadingOut {
    DateTime now = DateTime.now();
    DateTime endTime = DateTime(
        now.year, now.month, now.day, widget._endTime!.hour,
        widget._endTime!.minute);
    DateTime fadeOutEndTime = DateTime(
        now.year, now.month, now.day, widget._endTime!.hour,
        widget._endTime!.minute).add(Duration(minutes: widget.fadeOut));
    if(!now.isAfter(endTime))
      now = now.add(Duration(days: 1));
    return now.isBefore(fadeOutEndTime);
  }


  Widget _buildCenterText() {
    if (_isFadingIn) {
      return Text(
        "Fading In",
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20.0),
      );
    } else if (_isNightMode) {
      return Text(
        "Night Mode",
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20.0),
      );
    } else if (_isTransitioning) {
      return Text(
        "Transitioning",
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20.0),
      );
    } else if (_isFadingOut) {
      return Text(
        "Fading Out",
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20.0),
      );
    } else {
      return Text(
        "OFF",
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20.0),
      );
    }
  }

  Color _buildColor() {
    if (_isFadingIn) {
      return sleepColor.withAlpha(128);
    } else if (_isNightMode) {
      return sleepColor;
    } else if (_isTransitioning) {
      return sleepColor.withAlpha(128);
    } else if (_isFadingOut) {
      return wakeColor;
    } else {
      return Colors.grey.shade300;
    }
  }


  double _calculateProgress() {
    if (widget._startTime == null || widget._endTime == null) {
      return 0.0;
    }

    DateTime now = DateTime.now();
    DateTime temp = DateTime(
        now.year, now.month, now.day, widget._startTime!.hour,
        widget._startTime!.minute);
    DateTime startTime = DateTime(
        now.year, now.month, now.day, widget._startTime!.hour,
        widget._startTime!.minute)
        .subtract(Duration(minutes: widget.fadeIn));
    if(!startTime.isAfter(temp))
      startTime = startTime.add(Duration(days: 1));
    DateTime endTimeWithFadeOut = DateTime(
        now.year, now.month, now.day, widget._endTime!.hour,
        widget._endTime!.minute)
        .add(Duration(minutes: widget.fadeOut));
    if(!now.isAfter(startTime))
      now = now.add(Duration(days: 1));
    if(!endTimeWithFadeOut.isAfter(startTime))
      endTimeWithFadeOut = endTimeWithFadeOut.add(Duration(days: 1));
    Duration totalDuration = endTimeWithFadeOut.difference(startTime);
    Duration elapsedTime = now.difference(startTime);
    double progress = elapsedTime.inMilliseconds / totalDuration.inMilliseconds;

    // Ensure progress is between 0 and 1
    progress = progress.clamp(0.0, 1.0);
    return progress;
  }


  void _showTimePicker(bool setStart) {
    showTimePicker(
      context: context,
      initialTime: setStart
          ? (widget._startTime ?? TimeOfDay.now())
          : (widget._endTime ?? TimeOfDay.now()),
    ).then((value) {
      setState(() {
        if (value != null) {
          if (setStart)
            widget._startTime = value!;
          else
            widget._endTime = value!;
        }
      });
    });
  }

  int limitTrans() {
    // Convert string times to DateTime objects
    if (widget._startTime == null || widget._endTime == null) return 0;
    int startTimeInMinutes =
        widget._startTime!.hour * 60 + widget._startTime!.minute;
    int endTimeInMinutes = widget._endTime!.hour * 60 + widget._endTime!.minute;

    // Calculate available time for the light to be on
    int availableTime = (startTimeInMinutes > endTimeInMinutes)
        ? 24 * 60 - (startTimeInMinutes - endTimeInMinutes)
        : endTimeInMinutes - startTimeInMinutes;

    // Calculate maximum allowed rise time and fade time (capped at 10 minutes)
    return availableTime.clamp(0, 120);
  }

  int limitFade() {
    // Convert string times to DateTime objects
    if (widget._startTime == null || widget._endTime == null) return 0;
    int startTimeInMinutes =
        widget._startTime!.hour * 60 + widget._startTime!.minute;
    int endTimeInMinutes = widget._endTime!.hour * 60 + widget._endTime!.minute;

    // Calculate available time for the light to be on
    int availableTime = (startTimeInMinutes > endTimeInMinutes)
        ? (startTimeInMinutes - endTimeInMinutes)
        : 24 * 60 - (startTimeInMinutes - endTimeInMinutes);

    // Calculate maximum allowed rise time and fade time (capped at 10 minutes)
    return availableTime.clamp(0, 120);
  }

  void _loadTimeSettings() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int startHour = prefs.getInt('startHour') ?? TimeOfDay
        .now()
        .hour;
    int startMinute = prefs.getInt('startMinute') ?? TimeOfDay
        .now()
        .minute;
    int endHour = prefs.getInt('endHour') ?? TimeOfDay
        .now()
        .hour;
    int endMinute = prefs.getInt('endMinute') ?? TimeOfDay
        .now()
        .minute;

    setState(() {
      widget._startTime = TimeOfDay(hour: startHour, minute: startMinute);
      widget._endTime = TimeOfDay(hour: endHour, minute: endMinute);
      widget.delayTime = prefs.getInt('delayTime') ?? 0;
      widget.fadeOut = prefs.getInt('fadeOut') ?? 0;
      widget.fadeIn = prefs.getInt('fadeIn') ?? 0;
      sleepColor = Color(prefs.getInt('sleepColor') ?? Colors.blue.value);
      wakeColor = Color(prefs.getInt('wakeColor') ?? Colors.blue.value);
      widget.transitionTime = prefs.getInt('transitionTime') ?? 0;
      widget.isLoading = false;
    });
  }

  void _saveTimeSettings() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setInt('startHour', widget._startTime!.hour);
    prefs.setInt('startMinute', widget._startTime!.minute);
    prefs.setInt('endHour', widget._endTime!.hour);
    prefs.setInt('endMinute', widget._endTime!.minute);
    prefs.setInt('delayTime', widget.delayTime);
    prefs.setInt('fadeOut', widget.fadeOut);
    prefs.setInt('fadeIn', widget.fadeIn);
    prefs.setInt('transitionTime', widget.transitionTime);
  }

  void _showInstructions() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Instructions"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "1. Set sleep and wake up times for the night light.\n"
                    "2. Set motion delay time,transition time, fade in time, and fade out time (in minutes) as desired.\n"
                    "2. Checkout the time graph for more details\n"
                    "3. Press 'Save Changes' to save the settings.",
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text("OK"),
            ),
          ],
        );
      },
    );
  }

  void _showGraph() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 30),
          title: Text("Time Graph"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              WidgetZoom(
                heroAnimationTag: 'tag',
                zoomWidget: Image.asset(
                  'assets/graph.jpg', width: 500,
                  height: 200,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text("OK"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white70,
      appBar: AppBar(
        centerTitle: true,
        automaticallyImplyLeading: false,
        backgroundColor: Colors.teal.shade800,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Night Light',
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        physics: BouncingScrollPhysics(),
        child: Center(
          child: widget.isLoading
              ? Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 20),
              Text(
                widget.loadingMessage,
                style: TextStyle(fontSize: 16),
              ),
            ],
          )
              : Column(
            //mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                 // Text("Choose Time Settings",style: TextStyle(fontSize: 20,fontWeight: FontWeight.bold),),
                  //SizedBox(width: 30,),
                  IconButton(
                    icon: Icon(Icons.auto_graph_outlined),
                    onPressed: () {
                      _showGraph();
                    },
                  ),
                  IconButton(
                    icon: Icon(Icons.help),
                    onPressed: () {
                      _showInstructions();
                    },
                  ),
                ],
              ),
             // SizedBox(height: 20,),
              ListTile(
                leading: Container(padding: EdgeInsets.all(5),
                  decoration: BoxDecoration(
                      shape: BoxShape.circle, color: Colors.teal.shade800),
                  child: Icon(
                    Icons.bedtime_rounded, color: Colors.white,),
                ),
                title: Text(
                  'Sleep Time',
                  style: TextStyle(
                    fontSize: 20,
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                trailing: OutlinedButton(
                  onPressed: () => _showTimePicker(true),
                  child:
                  Text.rich(
                    TextSpan(
                      text: (widget._startTime != null
                          ? widget._startTime!
                          .format(context)
                          : TimeOfDay.now().format(context)),
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black),

                    ),
                  ),
                ),
              ),

              SizedBox(
                height: 25,
              ),
              ListTile(
                leading: Container(padding: EdgeInsets.all(5),
                  decoration: BoxDecoration(
                      shape: BoxShape.circle, color: Colors.teal.shade800),
                  child: Icon(
                    Icons.sunny, color: Colors.white,),
                ),
                title: Text(
                  'Wake Up Time',
                  style: TextStyle(
                    fontSize: 20,
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                trailing: OutlinedButton(
                  onPressed: () => _showTimePicker(false),
                  child: Text.rich(
                    TextSpan(
                      text:
                          (widget._endTime != null
                              ? widget._endTime!
                              .format(context)
                              : TimeOfDay.now().format(context)),
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black),

                    ),
                  ),
                ),
              ),

              /*
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  OutlinedButton(
                    onPressed: () => _showTimePicker(true),
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                          horizontal: 5.0, vertical: 25.0),
                      child: Text.rich(
                        TextSpan(
                          text: 'Sleep Time',
                          style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.black),
                          children: [
                            TextSpan(
                              text: "\n" +
                                  (widget._startTime != null
                                      ? widget._startTime!
                                      .format(context)
                                      : TimeOfDay.now().format(context)),
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 20,
                  ),
                  OutlinedButton(
                    onPressed: () => _showTimePicker(false),
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                          horizontal: 5.0, vertical: 25.0),
                      child: Text.rich(
                        TextSpan(
                          text: 'Wake Up Time',
                          style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.black),
                          children: [
                            TextSpan(
                              text: "\n" +
                                  (widget._endTime != null
                                      ? widget._endTime!
                                      .format(context)
                                      : TimeOfDay.now().format(context)),
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
               */
              SizedBox(
                height: 25,
              ),

              ListTile(
                leading: Container(padding: EdgeInsets.all(5),
                  decoration: BoxDecoration(
                      shape: BoxShape.circle, color: Colors.teal.shade800),
                  child: Icon(Icons.arrow_upward_rounded, color: Colors.white,),
                ),
                title: Text(
                  'Fade In',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                trailing:
                Container(
                  width: 60,
                  /*decoration: BoxDecoration(
                    border: Border.all(
                      color: Colors.grey, // Set border color
                      width: 1.0, // Set border width
                    ),
                    borderRadius: BorderRadius.all(
                      Radius.circular(4.0), // Adjust border radius as needed
                    ),
                  ),*/

                  child: DropdownButton<int>(
                    value: min(
                        widget.fadeIn, max((limitFade() - widget.fadeOut), 0)),
                    onChanged: (int? newValue) {
                      setState(() {
                        widget.fadeIn = newValue!;
                      });
                    },
                    items: List.generate(
                      max((limitFade() - widget.fadeOut) + 1, 1),
                          (index) {
                        return DropdownMenuItem<int>(
                          value: index,
                          child: Text(index.toString()),
                        );
                      },
                    ),
                    style: TextStyle(
                      fontSize: 18.0, // Adjust font size
                      color: Colors.black, // Adjust text color
                    ),
                    dropdownColor: Colors.white,
                    // Adjust dropdown background color
                    elevation: 4,
                    // Adjust elevation
                    icon: Icon(Icons.arrow_drop_down),
                    // Customize dropdown icon
                    iconSize: 24.0,
                    // Adjust icon size
                    isDense: true,
                    // Reduce vertical padding
                    underline: Container( // Customize underline
                      height: 2,
                      color: Colors.black, // Adjust underline color
                    ),
                  ),
                ),
              ),
              SizedBox(height: 25,),

              ListTile(
                leading: Container(padding: EdgeInsets.all(5),
                  decoration: BoxDecoration(
                      shape: BoxShape.circle, color: Colors.teal.shade800),
                  child: Icon(
                    Icons.arrow_downward_rounded, color: Colors.white,),
                ),
                title: Text(
                  'Fade Out',
                  style: TextStyle(
                    fontSize: 20,
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                trailing: Container(
                  width: 60,
                  /*decoration: BoxDecoration(
                    border: Border.all(
                      color: Colors.grey, // Set border color
                      width: 1.0, // Set border width
                    ),
                    borderRadius: BorderRadius.all(
                      Radius.circular(4.0), // Adjust border radius as needed
                    ),
                  ),*/
                  child:
                  DropdownButton<int>(
                    value: min(
                        widget.fadeOut, max((limitFade() - widget.fadeIn), 0)),
                    onChanged: (int? newValue) {
                      setState(() {
                        widget.fadeOut = newValue!;
                      });
                    },
                    items: List.generate(
                      max((limitFade() - widget.fadeIn) + 1, 1),
                          (index) {
                        return DropdownMenuItem<int>(
                          value: index,
                          child: Text(index.toString()),
                        );
                      },
                    ),
                    style: TextStyle(
                      fontSize: 18.0, // Adjust font size
                      color: Colors.black, // Adjust text color
                    ),
                    dropdownColor: Colors.white,
                    // Adjust dropdown background color
                    elevation: 4,
                    // Adjust elevation
                    icon: Icon(Icons.arrow_drop_down),
                    // Customize dropdown icon
                    iconSize: 24.0,
                    // Adjust icon size
                    isDense: true,
                    // Reduce vertical padding
                    underline: Container( // Customize underline
                      height: 2,
                      color: Colors.black,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 25,),
              ListTile(
                leading: Container(padding: EdgeInsets.all(5),
                  decoration: BoxDecoration(
                      shape: BoxShape.circle, color: Colors.teal.shade800),
                  child: Icon(Icons.transform_rounded, color: Colors.white,),
                ),
                title: Text(
                  'Transition Time',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Alef',
                  ),
                ),
                trailing: Container(
                  width: 60,
                  /*decoration: BoxDecoration(
                    border: Border.all(
                      color: Colors.grey, // Set border color
                      width: 1.0, // Set border width
                    ),
                    borderRadius: BorderRadius.all(
                      Radius.circular(4.0), // Adjust border radius as needed
                    ),
                  ),*/
                  child: DropdownButton<int>(
                    value: min(widget.transitionTime, limitTrans()),
                    onChanged: (int? newValue) {
                      setState(() {
                        widget.transitionTime = newValue!;
                      });
                    },
                    items: List.generate(
                      limitTrans() + 1,
                          (index) {
                        return DropdownMenuItem<int>(
                          value: index,
                          child: Text(index.toString()),
                        );
                      },
                    ),
                    style: TextStyle(
                      fontSize: 18.0, // Adjust font size
                      color: Colors.black, // Adjust text color
                    ),
                    dropdownColor: Colors.white,
                    // Adjust dropdown background color
                    elevation: 4,
                    // Adjust elevation
                    icon: Icon(Icons.arrow_drop_down),
                    // Customize dropdown icon
                    iconSize: 24.0,
                    // Adjust icon size
                    isDense: true,
                    // Reduce vertical padding
                    underline: Container( // Customize underline
                      height: 2,
                      color: Colors.black,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 25,),
              ListTile(
                leading: Container(padding: EdgeInsets.all(5),
                  decoration: BoxDecoration(
                      shape: BoxShape.circle, color: Colors.teal.shade800),
                  child: Icon(Icons.directions_walk, color: Colors.white,),
                ),
                title: Text(
                  'Motion Delay Time',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Alef',
                  ),
                ),
                trailing: Container(
                  width: 60,
                  /*decoration: BoxDecoration(
                    border: Border.all(
                      color: Colors.grey, // Set border color
                      width: 1.0, // Set border width
                    ),
                    borderRadius: BorderRadius.all(
                      Radius.circular(4.0), // Adjust border radius as needed
                    ),
                  ),*/
                  child: DropdownButton<int>(
                    value: widget.delayTime,
                    onChanged: (int? newValue) {
                      setState(() {
                        widget.delayTime = newValue!;
                      });
                    },
                    items: List.generate(
                      11,
                          (index) {
                        return DropdownMenuItem<int>(
                          value: index,
                          child: Text(index.toString()),
                        );
                      },
                    ),
                    style: TextStyle(
                      fontSize: 18.0, // Adjust font size
                      color: Colors.black, // Adjust text color
                    ),
                    dropdownColor: Colors.white,
                    // Adjust dropdown background color
                    elevation: 4,
                    // Adjust elevation
                    icon: Icon(Icons.arrow_drop_down),
                    // Customize dropdown icon
                    iconSize: 24.0,
                    // Adjust icon size
                    isDense: true,
                    // Reduce vertical padding
                    underline: Container( // Customize underline
                      height: 2,
                      color: Colors.black,
                    ),

                  ),
                ),
              ),
              SizedBox(height: 30),
              ElevatedButton(
                onPressed: () {
                  _saveTimeSettings();
                  var start = widget._startTime ?? TimeOfDay.now();
                  var end = widget._endTime ?? TimeOfDay.now();
                  var data =
                      '${start.hour}+${start.minute}+${end.hour}+${end
                      .minute}+${widget.fadeOut}+${widget.fadeIn}+${widget
                      .delayTime}+${widget.transitionTime}';
                  writeDataWithCharacteristic(
                      widget.c_uid, data, context);
                  Widget okButton = TextButton(
                    child: Text("OK"),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  );
                  AlertDialog alert = AlertDialog(
                    title: Row(
                      children: [
                      Icon(Icons.check_circle,color: Colors.green,), // Add an icon if you want
                    SizedBox(width: 8), // Add some space between the icon and text
                        Text("Time Cycle Settings Changed",style: TextStyle(fontSize: 17),),
                    ]

                    ),

                    actions: [
                      okButton,
                    ],
                  );
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return alert;
                    },
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal.shade800,
                  minimumSize: Size(300, 40),
                ),
                child: Text(
                  'Save Changes',
                  style: TextStyle(color: Colors.white),
                ),
              ),
              SizedBox(height: 30),
              CircularPercentIndicator(
                radius: 100.0,
                animation: true,
                animateFromLastPercent: true,
                animationDuration: 2000,
                lineWidth: 15.0,
                percent: _progress,
                center: _buildCenterText(),
                circularStrokeCap: CircularStrokeCap.butt,
                backgroundColor: Colors.grey.shade300,
                progressColor: _buildColor(),
              ),
              SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }


}