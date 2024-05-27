import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:flutter/material.dart';
import 'sign_in_screen.dart';
import 'home_screen.dart'; 
import 'log_entry_screen.dart';
import 'reporting_screen.dart';
import 'profile_screen.dart';
import 'goals_screen.dart'; // Import the GoalsScreen
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions().currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final FirebaseAuth auth = FirebaseAuth.instance;
    final FirebaseFirestore firestore = FirebaseFirestore.instance;

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
        '/goals': (context) => GoalsScreen(auth: auth, firestore: firestore), // Pass instances
      },
    );
  }
}
