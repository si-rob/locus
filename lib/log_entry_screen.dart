import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LogEntryScreen extends StatefulWidget {
  const LogEntryScreen({super.key});

  @override
  LogEntryScreenState createState() => LogEntryScreenState();
}

class LogEntryScreenState extends State<LogEntryScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final TextEditingController _interactionController = TextEditingController();
  final TextEditingController _actionController = TextEditingController();
  final TextEditingController _categoryController = TextEditingController();
  final TextEditingController _timeTakenController = TextEditingController(); // New field for time taken

  Future<void> _saveLogEntry() async {
    final User? user = _auth.currentUser;
    if (user != null) {
      try {
        await _firestore.collection('logEntries').add({
          'userId': user.uid,
          'timestamp': Timestamp.now(),
          'interactionWith': _interactionController.text,
          'action': _actionController.text,
          'category': _categoryController.text,
          'timeTaken': double.tryParse(_timeTakenController.text) ?? 0.0, // Save the time taken
        });
        if (!mounted) return;
        setState(() {
          _interactionController.clear();
          _actionController.clear();
          _categoryController.clear();
          _timeTakenController.clear();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Log entry saved!')),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save log entry: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Log Entry')),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _interactionController,
              decoration: const InputDecoration(
                labelText: 'Interaction With',
                border: OutlineInputBorder(),
              ),
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _actionController,
              decoration: const InputDecoration(
                labelText: 'Action',
                border: OutlineInputBorder(),
              ),
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _categoryController,
              decoration: const InputDecoration(
                labelText: 'Category',
                border: OutlineInputBorder(),
              ),
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _timeTakenController,
              decoration: const InputDecoration(
                labelText: 'Time Taken (minutes)',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: _saveLogEntry,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 15),
                textStyle: const TextStyle(fontSize: 18),
              ),
              child: const Text('Save Log Entry'),
            ),
          ],
        ),
      ),
    );
  }
}
