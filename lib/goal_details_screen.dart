import 'package:flutter/material.dart';

class GoalDetailsScreen extends StatefulWidget {
  final Map<String, dynamic>? goal;
  final Future<Map<String, dynamic>> Function(Map<String, dynamic>) onSave;

  const GoalDetailsScreen({this.goal, required this.onSave, super.key});

  @override
  GoalDetailsScreenState createState() => GoalDetailsScreenState();
}

class GoalDetailsScreenState extends State<GoalDetailsScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _goalTypeController = TextEditingController();
  final TextEditingController _goalDurationController = TextEditingController();
  final TextEditingController _goalCompletionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.goal != null) {
      _titleController.text = widget.goal!['title'];
      _goalTypeController.text = widget.goal!['goalType'] ?? '';
      _goalDurationController.text = widget.goal!['goalDuration'] ?? '';
      _goalCompletionController.text = widget.goal!['goalCompletion'].toString();
    }
  }

  Future<void> _saveGoal() async {
    final Map<String, dynamic> updatedGoal = {
      'id': widget.goal?['id'], // Preserve the ID if editing an existing goal
      'title': _titleController.text,
      'goalType': _goalTypeController.text,
      'goalDuration': _goalDurationController.text,
      'goalCompletion': double.tryParse(_goalCompletionController.text) ?? 0.0,
    };

    final result = await widget.onSave(updatedGoal);
    if (mounted) {
      Navigator.pop(context, result);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Goal Details')),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Goal Title',
                border: OutlineInputBorder(),
              ),
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _goalTypeController,
              decoration: const InputDecoration(
                labelText: 'Goal Type',
                border: OutlineInputBorder(),
              ),
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _goalDurationController,
              decoration: const InputDecoration(
                labelText: 'Goal Duration',
                border: OutlineInputBorder(),
              ),
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _goalCompletionController,
              decoration: const InputDecoration(
                labelText: 'Goal Completion (%)',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: _saveGoal,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 15),
                textStyle: const TextStyle(fontSize: 18),
              ),
              child: const Text('Save Goal'),
            ),
          ],
        ),
      ),
    );
  }
}
