import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:flutter/material.dart';
import 'sign_in_screen.dart';
import 'home_screen.dart'; 
import 'log_entry_screen.dart';
import 'notification_settings_screen.dart';
import 'reporting_screen.dart';
import 'profile_screen.dart';
import 'goals_screen.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions().currentPlatform,
  );
  tz.initializeTimeZones();
  final String currentTimeZone =  await FlutterTimezone.getLocalTimezone();
  tz.setLocalLocation(tz.getLocation(currentTimeZone));
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = FirebaseAuth.instance;
    final firestore = FirebaseFirestore.instance;

    return MaterialApp(
      title: 'Locus',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const SignInScreen(),
        '/home': (context) => const HomeScreen(),
        '/log': (context) => const LogEntryScreen(),
        '/report': (context) => ReportingScreen(),
        '/profile': (context) => const ProfileScreen(),
        '/goals': (context) => GoalsScreen(auth: auth, firestore: firestore),
        '/notifications': (context) => const NotificationSettingsScreen(), // Add this route
      },
    );
  }
}
