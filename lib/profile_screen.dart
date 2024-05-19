import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProfileScreen extends StatefulWidget {
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final TextEditingController _goalController = TextEditingController();
  List<String> _goals = [];

  void _addGoal() {
    setState(() {
      _goals.add(_goalController.text);
      _goalController.clear();
    });
  }

  void _saveGoals() async {
    final User? user = _auth.currentUser;
    if (user != null) {
      await _firestore.collection('users').doc(user.uid).set({
        'goals': _goals,
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Goals saved!')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Profile')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _goalController,
              decoration: InputDecoration(labelText: 'New Goal'),
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: _addGoal,
              child: Text('Add Goal'),
            ),
            SizedBox(height: 20),
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
              child: Text('Save Goals'),
            )
          ],
        ),
      ),
    );
  }
}
