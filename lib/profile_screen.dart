import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  ProfileScreenState createState() => ProfileScreenState();
}

class ProfileScreenState extends State<ProfileScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final TextEditingController _goalController = TextEditingController();
  final List<String> _goals = [];

  void _addGoal() {
    setState(() {
      _goals.add(_goalController.text);
      _goalController.clear();
    });
  }

  Future<void> _saveGoals() async {
    final User? user = _auth.currentUser;
    if (user != null) {
      await _firestore.collection('users').doc(user.uid).set({
        'goals': _goals,
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Goals saved!'))
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _goalController,
              decoration: const InputDecoration(labelText: 'New Goal'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _addGoal,
              child: const Text('Add Goal'),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: _goals.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text(_goals[index]),
                  );
                },
              ),
            ),
            ElevatedButton(
              onPressed: _saveGoals,
              child: const Text('Save Goals'),
            ),
          ],
        ),
      ),
    );
  }
}
