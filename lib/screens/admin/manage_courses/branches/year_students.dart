import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class YearStudentListPage extends StatelessWidget {
  final String courseName;
  final String branchName;
  final String year;
  final String section;   // 🔥 NEW

  const YearStudentListPage({
    super.key,
    required this.courseName,
    required this.branchName,
    required this.year,
    required this.section,   // 🔥 NEW
  });

  @override
  Widget build(BuildContext context) {
    final studentsRef = FirebaseFirestore.instance
        .collection('students')
        .where('course', isEqualTo: courseName)
        .where('branch', isEqualTo: branchName)
        .where('year', isEqualTo: year)
        .where('section', isEqualTo: section);   // 🔥 FILTER ADDED

    return Scaffold(
      appBar: AppBar(
        title: Text("$branchName - $year - Section $section"),
        backgroundColor: Colors.purpleAccent,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: studentsRef.snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final students = snapshot.data!.docs;
          if (students.isEmpty) {
            return const Center(child: Text("No students found"));
          }

          return ListView.builder(
            itemCount: students.length,
            itemBuilder: (context, index) {
              final data = students[index].data() as Map<String, dynamic>;
              final name = data['name'] ?? 'Unknown';
              final rollNo = data['rollNo'] ?? '';
              final email = data['email'] ?? '';

              return Card(
                margin: const EdgeInsets.all(10),
                child: ListTile(
                  leading: const Icon(Icons.person, color: Colors.blue),
                  title: Text(
                    name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text("Roll No: $rollNo\nEmail: $email"),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
