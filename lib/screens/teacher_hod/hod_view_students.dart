import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HODViewStudentsPage extends StatelessWidget {
  final String course;
  final String branch;

  const HODViewStudentsPage({
    super.key,
    required this.course,
    required this.branch,
  });

  @override
  Widget build(BuildContext context) {
    final studentsRef = FirebaseFirestore.instance
        .collection('students')
        .where('course', isEqualTo: course)
        .where('branch', isEqualTo: branch)
        .orderBy('rollNo'); // orderBy kept

    return Scaffold(
      appBar: AppBar(
        title: Text("$branch - Students"),
        backgroundColor: Colors.blue,
      ),
      backgroundColor: Colors.blue[50],
      body: StreamBuilder<QuerySnapshot>(
        stream: studentsRef.snapshots(),
        builder: (context, snap) {
          // loading
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // error (index / permission)
          if (snap.hasError) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  "Query error ❌\nCreate composite index:\n"
                  "students → course (ASC), branch (ASC), rollNo (ASC)",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.red),
                ),
              ),
            );
          }

          if (!snap.hasData || snap.data!.docs.isEmpty) {
            return const Center(child: Text("No students found"));
          }

          final docs = snap.data!.docs;

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, i) {
              final student = docs[i].data() as Map<String, dynamic>;

              return Card(
                margin: const EdgeInsets.all(12),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.blue,
                    child: Text(
                      student['rollNo']?.toString() ?? '-',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  title: Text(student['name'] ?? 'No Name'),
                  subtitle: Text(
                    "Email: ${student['email'] ?? '-'}\n"
                    "Year: ${student['year'] ?? '-'}",
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
