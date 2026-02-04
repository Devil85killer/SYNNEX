import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class StudentApproval extends StatefulWidget {
  const StudentApproval({super.key});

  @override
  State<StudentApproval> createState() => _StudentApprovalState();
}

class _StudentApprovalState extends State<StudentApproval> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> _approveStudent(String id) async {
    await _firestore.collection('students').doc(id).update({'approved': true});
  }

  Future<void> _rejectStudent(String id) async {
    await _firestore.collection('students').doc(id).delete();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore.collection('students').where('approved', isEqualTo: false).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text("No pending students for approval"));
        }

        final students = snapshot.data!.docs;

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: students.length,
          itemBuilder: (context, index) {
            final student = students[index];
            return Card(
              elevation: 4,
              margin: const EdgeInsets.symmetric(vertical: 8),
              child: ListTile(
                title: Text(student['name'] ?? 'Unknown'),
                subtitle: Text("Roll No: ${student['rollNo']} | Email: ${student['email']}"),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.check_circle, color: Colors.green),
                      onPressed: () => _approveStudent(student.id),
                    ),
                    IconButton(
                      icon: const Icon(Icons.cancel, color: Colors.red),
                      onPressed: () => _rejectStudent(student.id),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
