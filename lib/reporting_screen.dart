import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'encryption_service.dart';
import 'package:intl/intl.dart';

class ReportingScreen extends StatelessWidget {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final EncryptionService _encryptionService = EncryptionService();
  final String reportType;

  ReportingScreen({required this.reportType, super.key});

  Future<Map<String, String>> _fetchGoalTitles() async {
    final User? user = _auth.currentUser;
    if (user != null) {
      final DocumentSnapshot userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (userDoc.exists) {
        final data = userDoc.data() as Map<String, dynamic>;
        if (data.containsKey('goals')) {
          final goalsData = data['goals'];
          if (goalsData is List) {
            final goalTitles = <String, String>{};
            for (final goal in goalsData.whereType<Map<String, dynamic>>()) {
              final decryptedTitle = await _encryptionService.decryptText(goal['title']);
              goalTitles[goal['id']] = decryptedTitle;
            }
            return goalTitles;
          }
        }
      }
    }
    return {};
  }

  Future<List<Map<String, dynamic>>> _fetchLogEntries() async {
    final User? user = _auth.currentUser;
    if (user != null) {
      DateTime rangeStart;
      switch (reportType) {
        case 'weekly':
          rangeStart = DateTime.now().subtract(const Duration(days: 7));
          break;
        case 'monthly':
          rangeStart = DateTime.now().subtract(const Duration(days: 30));
          break;
        case 'daily':
        default:
          rangeStart = DateTime.now().subtract(const Duration(days: 1));
          break;
      }

      final QuerySnapshot querySnapshot = await _firestore
          .collection('logEntries')
          .where('userId', isEqualTo: user.uid)
          .where('timestamp', isGreaterThan: Timestamp.fromDate(rangeStart))
          .orderBy('timestamp', descending: true)
          .get();

      return Future.wait(querySnapshot.docs.map((doc) async {
        final data = doc.data() as Map<String, dynamic>;
        return {
          'timestamp': data['timestamp'],
          'interactionWith': await _encryptionService.decryptText(data['interactionWith']),
          'action': await _encryptionService.decryptText(data['action']),
          'category': await _encryptionService.decryptText(data['category']),
          'timeTaken': await _encryptionService.decryptText(data['timeTaken']), // Decrypt timeTaken
          'goalId': data['goalId'],
        };
      }).toList());
    }
    return [];
  }

  String _formatTimestamp(Timestamp timestamp) {
    final dateTime = timestamp.toDate();
    switch (reportType) {
      case 'weekly':
      case 'monthly':
        return DateFormat('yyyy-MM-dd HH:mm').format(dateTime); // Include date and time
      case 'daily':
      default:
        return DateFormat('HH:mm').format(dateTime); // Only time
    }
  }

  Future<String> _generateSummary(List<Map<String, dynamic>> logEntries) async {
    // Generate a summary of the log entries here
    // This can be customized as needed
    return "Summary of the $reportType activities";
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
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
            return FutureBuilder<Map<String, String>>(
              future: _fetchGoalTitles(),
              builder: (context, goalSnapshot) {
                if (goalSnapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (goalSnapshot.hasError) {
                  return Center(child: Text('Error fetching goals: ${goalSnapshot.error}'));
                } else if (goalSnapshot.hasData) {
                  final goalTitles = goalSnapshot.data!;
                  return FutureBuilder<String>(
                    future: _generateSummary(logEntries),
                    builder: (context, summarySnapshot) {
                      if (summarySnapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      } else if (summarySnapshot.hasError) {
                        return Center(child: Text('Error generating summary: ${summarySnapshot.error}'));
                      } else if (summarySnapshot.hasData) {
                        final summary = summarySnapshot.data!;
                        return ListView(
                          children: [
                            Card(
                              margin: const EdgeInsets.symmetric(vertical: 10),
                              child: Padding(
                                padding: const EdgeInsets.all(15),
                                child: Text(summary, style: const TextStyle(fontSize: 18)),
                              ),
                            ),
                            ...logEntries.map((logEntry) => Card(
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
                                    const SizedBox(height: 5),
                                    Text(
                                      'Goal: ${goalTitles[logEntry['goalId']] ?? 'No goal'}',
                                      style: const TextStyle(fontSize: 16),
                                    ),
                                  ],
                                ),
                              ),
                            )),
                          ],
                        );
                      }
                      return const Center(child: Text('No log entries found'));
                    },
                  );
                }
                return const Center(child: Text('No log entries found'));
              },
            );
          } else {
            return const Center(child: Text('No log entries found'));
          }
        },
      ),
    );
  }
}
