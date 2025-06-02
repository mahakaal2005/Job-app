import 'package:flutter/material.dart';

class EmpAnalytics extends StatelessWidget {
  const EmpAnalytics({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Example analytics data
    final analyticsData = [
      {'title': 'Total Hours Worked', 'value': '120'},
      {'title': 'Projects Completed', 'value': '8'},
      {'title': 'Tasks Pending', 'value': '3'},
      {'title': 'Attendance Rate', 'value': '95%'},
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Employee Analytics'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView.builder(
          itemCount: analyticsData.length,
          itemBuilder: (context, index) {
            final item = analyticsData[index];
            return Card(
              margin: const EdgeInsets.symmetric(vertical: 8),
              child: ListTile(
                leading: Icon(Icons.analytics),
                title: Text(item['title']!),
                trailing: Text(
                  item['value']!,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}