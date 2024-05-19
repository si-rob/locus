import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:flutter/material.dart';
import 'sign_in_screen.dart';
import 'home_screen.dart'; 
import 'log_entry_screen.dart';
import 'reporting_screen.dart';
import 'profile_screen.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';


void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  await Firebase.initializeApp(
  options: DefaultFirebaseOptions().currentPlatform,
);
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Locus',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => SignInScreen(),
        '/home': (context) => HomeScreen(),
        '/log': (context) => LogEntryScreen(),
        '/report': (context) => ReportingScreen(),
        '/profile': (context) => ProfileScreen(),
      },
    );
  }
}
