import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HODStudentsPage extends StatelessWidget {
  final String course;
  final String branch;

  const HODStudentsPage({
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
        .orderBy('year')        // ✅ keep
        .orderBy('rollno');     // ✅ FIXED (lowercase)

    return Scaffold(
      appBar: AppBar(
        title: Text("$branch Students"),
        backgroundColor: Colors.blue,
      ),
      backgroundColor: Colors.blue[50],

      body: StreamBuilder<QuerySnapshot>(
        stream: studentsRef.snapshots(),
        builder: (context, snapshot) {

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return const Center(
              child: Text(
                "Query error ❌\nCheck field names",
                style: TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text("No students found"),
            );
          }

          final students = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: students.length,
            itemBuilder: (context, index) {
              final data =
                  students[index].data() as Map<String, dynamic>;

              return Card(
                elevation: 4,
                margin: const EdgeInsets.symmetric(vertical: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.blue,
                    child: Text(
                      data['rollno']?.toString() ?? "-", // ✅ FIXED
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  title: Text(
                    data['name'] ?? "No Name",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    "Year: ${data['year'] ?? '-'}  •  Email: ${data['email'] ?? '-'}",
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
