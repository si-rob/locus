import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ReportingScreen extends StatelessWidget {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<Map<String, dynamic>>> _fetchLogEntries() async {
    final User? user = _auth.currentUser;
    if (user != null) {
      final QuerySnapshot querySnapshot = await _firestore
          .collection('logEntries')
          .where('userId', isEqualTo: user.uid)
          .where('timestamp', isGreaterThan: Timestamp.fromDate(DateTime.now().subtract(Duration(days: 1))))
          .orderBy('timestamp', descending: true)
          .get();

      return querySnapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
    }
    return [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Daily Report')),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _fetchLogEntries(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error fetching log entries: ${snapshot.error}'));
          } else if (snapshot.hasData) {
            final logEntries = snapshot.data!;
            return ListView.builder(
              itemCount: logEntries.length,
              itemBuilder: (context, index) {
                final logEntry = logEntries[index];
                final interactions = logEntry['interactions'] as List<dynamic>;
                final interactionDetails = interactions.isNotEmpty ? interactions[0] : {};
                return ListTile(
                  title: Text(logEntry['timestamp'].toDate().toString()),
                  subtitle: Text(interactionDetails['action'] ?? 'No action'),
                );
              },
            );
          } else {
            return Center(child: Text('No log entries found'));
          }
        },
      ),
    );
  }
}
