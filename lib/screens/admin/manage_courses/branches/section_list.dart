import 'package:flutter/material.dart';
import 'year_students.dart';

class SectionListPage extends StatelessWidget {
  final String courseName;
  final String branchName;
  final String year;

  const SectionListPage({
    super.key,
    required this.courseName,
    required this.branchName,
    required this.year,
  });

  @override
  Widget build(BuildContext context) {
    final List<String> sections = ["A", "B", "C", "D"]; // You can expand later

    return Scaffold(
      appBar: AppBar(
        title: Text("$branchName - $year - Sections"),
        backgroundColor: Colors.deepPurple,
      ),
      body: ListView.builder(
        itemCount: sections.length,
        itemBuilder: (context, index) {
          final sec = sections[index];

          return Card(
            margin: const EdgeInsets.all(10),
            elevation: 2,
            child: ListTile(
              leading: const Icon(Icons.group, color: Colors.deepPurple),
              title: Text(
                "Section $sec",
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => YearStudentListPage(
                      courseName: courseName,
                      branchName: branchName,
                      year: year,
                      section: sec, // ⭐ FINAL FIX
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
