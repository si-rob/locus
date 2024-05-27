import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'encryption_service.dart';

class LogEntryScreen extends StatefulWidget {
  const LogEntryScreen({super.key});

  @override
  LogEntryScreenState createState() => LogEntryScreenState();
}

class LogEntryScreenState extends State<LogEntryScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final EncryptionService _encryptionService = EncryptionService();

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
              'interactionWith': await _encryptionService.encryptText(_interactionController.text),
              'action': await _encryptionService.encryptText(_actionController.text),
              'category': await _encryptionService.encryptText(_categoryController.text),
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
