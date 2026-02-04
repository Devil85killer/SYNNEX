import 'package:flutter/material.dart';
import 'section_list.dart';

class StudentYearListPage extends StatelessWidget {
  final String courseName;
  final String branchName;
  final int totalYears;

  const StudentYearListPage({
    super.key,
    required this.courseName,
    required this.branchName,
    required this.totalYears,
  });

  @override
  Widget build(BuildContext context) {
    final years = List.generate(
      totalYears,
      (i) => "${i + 1}${_getYearSuffix(i + 1)} Year",
    );

    return Scaffold(
      appBar: AppBar(
        title: Text("$branchName - Students"),
        backgroundColor: Colors.deepPurple,
      ),
      body: ListView.builder(
        itemCount: years.length,
        itemBuilder: (context, index) {
          final yearName = years[index];

          return Card(
            margin: const EdgeInsets.all(10),
            elevation: 3,
            child: ListTile(
              leading: const Icon(Icons.school, color: Colors.deepPurple),
              title: Text(
                yearName,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => SectionListPage(
                      courseName: courseName,
                      branchName: branchName,
                      year: yearName,
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

  String _getYearSuffix(int year) {
    if (year == 1) return "st";
    if (year == 2) return "nd";
    if (year == 3) return "rd";
    return "th";
  }
}
