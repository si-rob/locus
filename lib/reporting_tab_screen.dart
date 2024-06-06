import 'package:flutter/material.dart';
import 'reporting_screen.dart'; // Assume this is the file with your existing reporting logic

class ReportingTabScreen extends StatefulWidget {
  const ReportingTabScreen({super.key});

  @override
  ReportingTabScreenState createState() => ReportingTabScreenState();
}

class ReportingTabScreenState extends State<ReportingTabScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Daily'),
            Tab(text: 'Weekly'),
            Tab(text: 'Monthly'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          ReportingScreen(reportType: 'daily'),
          ReportingScreen(reportType: 'weekly'),
          ReportingScreen(reportType: 'monthly'),
        ],
      ),
    );
  }
}
