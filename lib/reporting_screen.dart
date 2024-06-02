import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'encryption_service.dart';
import 'package:intl/intl.dart';

class ReportingScreen extends StatelessWidget {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final EncryptionService _encryptionService = EncryptionService();

  ReportingScreen({super.key});

  Future<List<Map<String, dynamic>>> _fetchLogEntries() async {
    final User? user = _auth.currentUser;
    if (user != null) {
      final QuerySnapshot querySnapshot = await _firestore
          .collection('logEntries')
          .where('userId', isEqualTo: user.uid)
          .where('timestamp', isGreaterThan: Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 1))))
          .orderBy('timestamp', descending: true)
          .get();

      return Future.wait(querySnapshot.docs.map((doc) async {
        final data = doc.data() as Map<String, dynamic>;
        final interactionWith = await _encryptionService.decryptText(data['interactionWith']);
        final action = await _encryptionService.decryptText(data['action']);
        final category = await _encryptionService.decryptText(data['category']);

        return {
          'userId': data['userId'],
          'timestamp': data['timestamp'],
          'interactionWith': interactionWith,
          'action': action,
          'category': category,
          'timeTaken': data['timeTaken'],
        };
      }).toList());
    }
    return [];
  }

  String _formatTimestamp(Timestamp timestamp) {
    final dateTime = timestamp.toDate();
    final formattedTime = DateFormat('HH:mm').format(dateTime);
    return formattedTime;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Daily Report')),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: _fetchLogEntries(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text('Error fetching log entries: ${snapshot.error}'));
            } else if (snapshot.hasData) {
              final logEntries = snapshot.data!;
              return ListView.builder(
                itemCount: logEntries.length,
                itemBuilder: (context, index) {
                  final logEntry = logEntries[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 10),
                    child: Padding(
                      padding: const EdgeInsets.all(15),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Time: ${_formatTimestamp(logEntry['timestamp'])}',
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Interaction With: ${logEntry['interactionWith']}',
                            style: const TextStyle(fontSize: 16),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            'Action: ${logEntry['action']}',
                            style: const TextStyle(fontSize: 16),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            'Category: ${logEntry['category']}',
                            style: const TextStyle(fontSize: 16),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            'Time Taken: ${logEntry['timeTaken']} minutes',
                            style: const TextStyle(fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            } else {
              return const Center(child: Text('No log entries found'));
            }
          },
        ),
      ),
    );
  }
}
