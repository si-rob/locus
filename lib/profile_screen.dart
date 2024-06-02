import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/foundation.dart'; // For kDebugMode

// Constants for notification settings
const String notificationChannelId = 'locus_notifications';
const String notificationChannelName = 'Locus Activity Reminders';
const String notificationChannelDescription = 'Notifications to remind you to log your activities every 30 minutes';
const int defaultNotificationInterval = 30; // Default to 30 minutes
const TimeOfDay defaultStartTime = TimeOfDay(hour: 8, minute: 0);
const TimeOfDay defaultEndTime = TimeOfDay(hour: 18, minute: 0);

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  ProfileScreenState createState() => ProfileScreenState();
}

class ProfileScreenState extends State<ProfileScreen> {
  bool _notificationsEnabled = false;
  int _notificationInterval = defaultNotificationInterval;
  TimeOfDay _startTime = defaultStartTime;
  TimeOfDay _endTime = defaultEndTime;

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  @override
  void initState() {
    super.initState();
    _loadPreferences();
    _initializeNotifications();
  }

  Future<void> _initializeNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('app_icon');
    final DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
      onDidReceiveLocalNotification: (id, title, body, payload) async {
        // Handle iOS notification received while app is in foreground
      },
    );
    final InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );
    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) async {
        if (kDebugMode) {
          print('Notification clicked with payload: ${response.payload}');
        }
        // Handle notification tapped logic here
        if (response.payload != null) {
          Navigator.pushNamed(context, '/log', arguments: response.payload);
        }
      },
    );

    // Create notification channel for Android
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      notificationChannelId,
      notificationChannelName,
      description: notificationChannelDescription,
      importance: Importance.high,
    );
    await flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()?.createNotificationChannel(channel);
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _notificationsEnabled = prefs.getBool('notificationsEnabled') ?? false;
      _notificationInterval = prefs.getInt('notificationInterval') ?? defaultNotificationInterval;
      _startTime = TimeOfDay(
        hour: prefs.getInt('startHour') ?? defaultStartTime.hour,
        minute: prefs.getInt('startMinute') ?? defaultStartTime.minute,
      );
      _endTime = TimeOfDay(
        hour: prefs.getInt('endHour') ?? defaultEndTime.hour,
        minute: prefs.getInt('endMinute') ?? defaultEndTime.minute,
      );

      // Ensure the notification interval is one of the valid values
      if (![15, 30, 60].contains(_notificationInterval)) {
        _notificationInterval = defaultNotificationInterval;
      }
    });
  }

  Future<void> _savePreferences() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setBool('notificationsEnabled', _notificationsEnabled);
    prefs.setInt('notificationInterval', _notificationInterval);
    prefs.setInt('startHour', _startTime.hour);
    prefs.setInt('startMinute', _startTime.minute);
    prefs.setInt('endHour', _endTime.hour);
    prefs.setInt('endMinute', _endTime.minute);
    if (_notificationsEnabled) {
      await _checkAndRequestPermissions();
      await _scheduleNotifications();
    } else {
      await _cancelNotifications();
    }
  }

  Future<void> _checkAndRequestPermissions() async {
    if (await Permission.notification.isDenied) {
      await Permission.notification.request();
    }

    if (await Permission.scheduleExactAlarm.isDenied) {
      await Permission.scheduleExactAlarm.request();
    }

    // Check if the notifications are enabled in system settings
    if (!(await Permission.notification.isGranted)) {
      openAppSettings();
    }
  }

  Future<void> _scheduleNotifications() async {
    await _cancelNotifications();

    // Get the current local time
    final now = tz.TZDateTime.now(tz.local);

    // Calculate the start and end times for the notifications based on user preferences
    var start = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      _startTime.hour,
      _startTime.minute,
    );

    var end = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      _endTime.hour,
      _endTime.minute,
    );

    // If the start time is before now, start from the next interval
    if (start.isBefore(now)) {
      start = start.add(Duration(
        minutes: _notificationInterval - now.minute % _notificationInterval,
      ));
    }

    // If the end time is before the start time, move the end time to the next day
    if (end.isBefore(start)) {
      end = end.add(const Duration(days: 1));
    }

    if (kDebugMode) {
      print('Now (local): $now');
      print('Start (local): $start');
      print('End (local): $end');
      print('Scheduling notifications from $start to $end every $_notificationInterval minutes.');
    }

    for (var time = start; time.isBefore(end); time = time.add(Duration(minutes: _notificationInterval))) {
      if (kDebugMode) {
        print('Scheduling notification for: $time');
      }
      await flutterLocalNotificationsPlugin.zonedSchedule(
        time.millisecondsSinceEpoch % 100000, // Unique ID for each notification
        'Time to log your activities!',
        'Tap to open and log your activities for the past $_notificationInterval minutes.',
        time,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            notificationChannelId,
            notificationChannelName,
            channelDescription: notificationChannelDescription,
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time, // Repeats daily at the specified time
        payload: 'Log your activities', // Payload for the notification
      );
    }
  }

  Future<void> _cancelNotifications() async {
    await flutterLocalNotificationsPlugin.cancelAll();
  }

  Future<void> _triggerImmediateNotification() async {
    await flutterLocalNotificationsPlugin.show(
      0,
      'Test Notification',
      'This is a test notification.',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          notificationChannelId,
          notificationChannelName,
          channelDescription: notificationChannelDescription,
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      payload: 'Log your activities', // Payload for the notification
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SwitchListTile(
              title: const Text('Enable Notifications'),
              value: _notificationsEnabled,
              onChanged: (value) async {
                setState(() {
                  _notificationsEnabled = value;
                });
                await _savePreferences();
              },
            ),
            const SizedBox(height: 20),
            ListTile(
              title: const Text('Notification Interval (minutes)'),
              trailing: DropdownButton<int>(
                value: _notificationInterval,
                items: [1, 15, 30, 60].map((int value) {
                  return DropdownMenuItem<int>(
                    value: value,
                    child: Text(value.toString()),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _notificationInterval = value!;
                  });
                },
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              title: const Text('Notification Start Time'),
              trailing: TextButton(
                onPressed: () async {
                  final TimeOfDay? picked = await showTimePicker(
                    context: context,
                    initialTime: _startTime,
                  );
                  if (picked != null && picked != _startTime) {
                    setState(() {
                      _startTime = picked;
                    });
                  }
                },
                child: Text(_startTime.format(context)),
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              title: const Text('Notification End Time'),
              trailing: TextButton(
                onPressed: () async {
                  final TimeOfDay? picked = await showTimePicker(
                    context: context,
                    initialTime: _endTime,
                  );
                  if (picked != null && picked != _endTime) {
                    setState(() {
                      _endTime = picked;
                    });
                  }
                },
                child: Text(_endTime.format(context)),
              ),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: _savePreferences,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 15),
                textStyle: const TextStyle(fontSize: 18),
              ),
              child: const Text('Save Preferences'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/goals');
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 15),
                textStyle: const TextStyle(fontSize: 18),
              ),
              child: const Text('Manage Goals'),
            ),
            if (kDebugMode) ...[
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _triggerImmediateNotification,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  textStyle: const TextStyle(fontSize: 18),
                ),
                child: const Text('Trigger Test Notification'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
