import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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

  Future<void> _saveLogEntry() async {
    final User? user = _auth.currentUser;
    if (user != null) {
      try {
        await _firestore.collection('logEntries').add({
          'userId': user.uid,
          'timestamp': Timestamp.now(),
          'interactions': [
            {
              'interactionWith': _interactionController.text,
              'action': _actionController.text,
              'category': _categoryController.text,
            }
          ]
        });
        if (!mounted) return;
        setState(() {
          _interactionController.clear();
          _actionController.clear();
          _categoryController.clear();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Log entry saved!'))
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save log entry: $e'))
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Log Entry')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _interactionController,
              decoration: const InputDecoration(labelText: 'Interaction With'),
            ),
            TextField(
              controller: _actionController,
              decoration: const InputDecoration(labelText: 'Action'),
            ),
            TextField(
              controller: _categoryController,
              decoration: const InputDecoration(labelText: 'Category'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _saveLogEntry,
              child: const Text('Save Log Entry'),
            ),
          ],
        ),
      ),
    );
  }
}
