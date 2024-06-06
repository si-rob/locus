import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'encryption_service.dart';
import 'goals_screen.dart';

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
  final TextEditingController _timeTakenController = TextEditingController(); // New field for time taken

  List<Map<String, dynamic>> _goals = [];
  String? _selectedGoalId;

  @override
  void initState() {
    super.initState();
    _fetchGoals();
  }

  Future<void> _fetchGoals() async {
    final User? user = _auth.currentUser;
    if (user != null) {
      final DocumentSnapshot userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (userDoc.exists) {
        final data = userDoc.data() as Map<String, dynamic>;
        if (data.containsKey('goals')) {
          final goalsData = data['goals'];
          if (goalsData is List) {
            final decryptedGoals = await Future.wait(goalsData.whereType<Map<String, dynamic>>().map((goal) async {
              return {
                'id': goal['id'],
                'title': await _encryptionService.decryptText(goal['title']),
              };
            }).toList());
            if (mounted) {
              setState(() {
                _goals = decryptedGoals;
              });
            }
          }
        }
      }
    }
  }

  Future<void> _saveLogEntry() async {
    final User? user = _auth.currentUser;
    if (user != null) {
      final interaction = _interactionController.text.trim();
      final action = _actionController.text.trim();
      final category = _categoryController.text.trim();
      final timeTaken = _timeTakenController.text.trim();

      if (interaction.isEmpty || action.isEmpty || category.isEmpty || timeTaken.isEmpty) {
        _showErrorMessage('All fields are required.');
        return;
      }

      try {
        final encryptedInteraction = await _encryptionService.encryptText(interaction);
        final encryptedAction = await _encryptionService.encryptText(action);
        final encryptedCategory = await _encryptionService.encryptText(category);
        final encryptedTimeTaken = await _encryptionService.encryptText(timeTaken);

        await _firestore.collection('logEntries').add({
          'userId': user.uid,
          'timestamp': Timestamp.now(),
          'interactionWith': encryptedInteraction,
          'action': encryptedAction,
          'category': encryptedCategory,
          'timeTaken': encryptedTimeTaken, // Save the time taken
          'goalId': _selectedGoalId, // Save the selected goal ID
        });
        if (!mounted) return;
        setState(() {
          _interactionController.clear();
          _actionController.clear();
          _categoryController.clear();
          _timeTakenController.clear();
          _selectedGoalId = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Log entry saved!')),
        );
      } catch (e) {
        _showErrorMessage('Failed to save log entry: ${e.toString()}');
      }
    }
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Log Entry')),
      body: SingleChildScrollView(
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
            const SizedBox(height: 20),
            DropdownButtonFormField<String>(
              value: _selectedGoalId,
              items: _goals.map((goal) {
                return DropdownMenuItem<String>(
                  value: goal['id'],
                  child: Text(goal['title']),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedGoalId = value;
                });
              },
              decoration: const InputDecoration(
                labelText: 'Select Goal',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => GoalsScreen(
                      auth: _auth,
                      firestore: _firestore,
                    ),
                  ),
                );
              },
              child: const Text('Add a new goal'),
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
