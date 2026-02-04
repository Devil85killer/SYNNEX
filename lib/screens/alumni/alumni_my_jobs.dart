import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'alumni_post_job.dart';

class AlumniMyJobsPage extends StatelessWidget {
  const AlumniMyJobsPage({super.key});

  Future<void> deleteJob(BuildContext context, String jobId) async {
    await FirebaseFirestore.instance
        .collection("jobs")
        .doc(jobId)
        .delete();

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Job deleted")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    // 🔒 SAFETY
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text("Please login again")),
      );
    }

    final uid = user.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text("My Job Posts"),
        backgroundColor: Colors.blue,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection("jobs")
            .where("postedBy", isEqualTo: uid)
            .orderBy("postedAt", descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                "You haven't posted any jobs yet.",
                style: TextStyle(fontSize: 16),
              ),
            );
          }

          final jobs = snapshot.data!.docs;

          return ListView.builder(
            itemCount: jobs.length,
            itemBuilder: (context, index) {
              final doc = jobs[index];
              final data = doc.data() as Map<String, dynamic>;

              return Card(
                margin:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                elevation: 4,
                child: ListTile(
                  title: Text(
                    data["title"] ?? "",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(data["company"] ?? ""),
                      Text(data["location"] ?? ""),
                    ],
                  ),
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == "edit") {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => AlumniPostJobPage(
                              jobId: doc.id,
                              existingData: data,
                            ),
                          ),
                        );
                      } else if (value == "delete") {
                        deleteJob(context, doc.id);
                      }
                    },
                    itemBuilder: (context) => const [
                      PopupMenuItem(value: "edit", child: Text("Edit")),
                      PopupMenuItem(value: "delete", child: Text("Delete")),
                    ],
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
