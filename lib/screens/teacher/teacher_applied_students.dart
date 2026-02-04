import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TeacherAppliedStudentsPage extends StatelessWidget {
  final String jobId;

  const TeacherAppliedStudentsPage({super.key, required this.jobId});

  @override
  Widget build(BuildContext context) {
    final appliedRef = FirebaseFirestore.instance
        .collection("alumni_jobs")
        .doc(jobId)
        .collection("applied_students");

    return Scaffold(
      appBar: AppBar(
        title: const Text("Applied Students"),
        backgroundColor: Colors.blue,
      ),
      body: StreamBuilder(
        stream: appliedRef.snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final applied = snapshot.data!.docs;

          if (applied.isEmpty) {
            return const Center(
              child: Text(
                "No students have applied yet.",
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            );
          }

          return ListView.builder(
            itemCount: applied.length,
            itemBuilder: (context, index) {
              final uid = applied[index]["uid"];

              return FutureBuilder(
                future: FirebaseFirestore.instance
                    .collection("students")
                    .doc(uid)
                    .get(),
                builder: (context, snap) {
                  if (!snap.hasData) {
                    return const ListTile(
                      title: Text("Loading student..."),
                    );
                  }

                  final data = snap.data!.data()!;
                  return Card(
                    margin: const EdgeInsets.all(12),
                    child: ListTile(
                      leading: const Icon(Icons.person),
                      title: Text(data["name"] ?? ""),
                      subtitle: Text(data["email"] ?? ""),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
