import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'encryption_service.dart';
import 'goal_details_screen.dart';
import 'package:uuid/uuid.dart';

class GoalsScreen extends StatefulWidget {
  final FirebaseAuth auth;
  final FirebaseFirestore firestore;

  const GoalsScreen({required this.auth, required this.firestore, super.key});

  @override
  GoalsScreenState createState() => GoalsScreenState();
}

class GoalsScreenState extends State<GoalsScreen> {
  late final FirebaseAuth _auth;
  late final FirebaseFirestore _firestore;
  final EncryptionService _encryptionService = EncryptionService();

  List<Map<String, dynamic>> _goals = [];

  @override
  void initState() {
    super.initState();
    _auth = widget.auth;
    _firestore = widget.firestore;
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
                'id': goal['id'] ?? const Uuid().v4(), // Generate ID if missing
                'title': await _encryptionService.decryptText(goal['title']),
                'goalType': goal['goalType'] != null ? await _encryptionService.decryptText(goal['goalType']) : null,
                'goalDuration': goal['goalDuration'] != null ? await _encryptionService.decryptText(goal['goalDuration']) : null,
                'goalCompletion': goal['goalCompletion'],
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

  Future<void> _deleteGoal(int index) async {
    final User? user = _auth.currentUser;
    if (user != null) {
      setState(() {
        _goals.removeAt(index);
      });
      await _saveGoals();
    }
  }

  void _editGoal(int index) async {
    final updatedGoal = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (context) => GoalDetailsScreen(
          goal: _goals[index],
          onSave: (updatedGoal) async {
            final encryptedGoal = await _encryptGoal(updatedGoal);
            return encryptedGoal;
          },
        ),
      ),
    );

    if (updatedGoal != null && mounted) {
      final decryptedGoal = await _decryptGoal(updatedGoal);
      setState(() {
        _goals[index] = decryptedGoal;
      });
      await _saveGoals();
    }
  }

  void _addGoal() async {
    final newGoal = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (context) => GoalDetailsScreen(
          onSave: (newGoal) async {
            newGoal['id'] = const Uuid().v4(); // Add ID to new goal
            final encryptedGoal = await _encryptGoal(newGoal);
            return encryptedGoal;
          },
        ),
      ),
    );

    if (newGoal != null && mounted) {
      final decryptedGoal = await _decryptGoal(newGoal);
      setState(() {
        _goals.add(decryptedGoal);
      });
      await _saveGoals();
    }
  }

  Future<Map<String, dynamic>> _encryptGoal(Map<String, dynamic> goal) async {
    return {
      'id': goal['id'],
      'title': await _encryptionService.encryptText(goal['title']),
      'goalType': goal['goalType'] != null ? await _encryptionService.encryptText(goal['goalType']) : null,
      'goalDuration': goal['goalDuration'] != null ? await _encryptionService.encryptText(goal['goalDuration']) : null,
      'goalCompletion': goal['goalCompletion'],
    };
  }

  Future<Map<String, dynamic>> _decryptGoal(Map<String, dynamic> goal) async {
    return {
      'id': goal['id'],
      'title': await _encryptionService.decryptText(goal['title']),
      'goalType': goal['goalType'] != null ? await _encryptionService.decryptText(goal['goalType']) : null,
      'goalDuration': goal['goalDuration'] != null ? await _encryptionService.decryptText(goal['goalDuration']) : null,
      'goalCompletion': goal['goalCompletion'],
    };
  }

  Future<void> _saveGoals() async {
    final User? user = _auth.currentUser;
    if (user != null) {
      final encryptedGoals = await Future.wait(_goals.map((goal) async {
        return await _encryptGoal(goal);
      }).toList());

      await _firestore.collection('users').doc(user.uid).set({
        'goals': encryptedGoals,
      }, SetOptions(merge: true)); // Use merge option to avoid overwriting
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Goals saved!')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manage Goals')),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: ListView.builder(
                itemCount: _goals.length,
                itemBuilder: (context, index) {
                  final goal = _goals[index];
                  return Dismissible(
                    key: Key(goal['id']),
                    onDismissed: (direction) {
                      _deleteGoal(index);
                    },
                    background: Container(color: Colors.red),
                    child: ListTile(
                      title: Text(
                        '⭐ ${goal['title']}',
                        style: const TextStyle(fontSize: 18),
                      ),
                      subtitle: Text(
                        '${goal['goalType'] ?? 'Unknown Type'} - ${goal['goalDuration'] ?? 'No Duration'}',
                        style: const TextStyle(fontSize: 16),
                      ),
                      onTap: () => _editGoal(index),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _addGoal,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  textStyle: const TextStyle(fontSize: 18),
                ),
                child: const Text('Add Goal'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
