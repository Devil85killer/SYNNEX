import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminAllAlumniPage extends StatefulWidget {
  const AdminAllAlumniPage({super.key});

  @override
  State<AdminAllAlumniPage> createState() => _AdminAllAlumniPageState();
}

class _AdminAllAlumniPageState extends State<AdminAllAlumniPage> {
  String selectedBatch = "All";
  String searchQuery = "";

  /// 🔥 DELETE JOB (ADMIN)
  Future<void> deleteJob(String jobId) async {
    await FirebaseFirestore.instance
        .collection("jobs")
        .doc(jobId)
        .delete();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Job deleted successfully")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("All Alumni"),
        backgroundColor: Colors.blueAccent,
      ),
      body: Column(
        children: [
          /// 🔍 SEARCH
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: "Search alumni...",
                border: OutlineInputBorder(),
              ),
              onChanged: (v) {
                setState(() => searchQuery = v.toLowerCase());
              },
            ),
          ),

          /// 🎓 BATCH FILTER
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                const Text("Batch:", style: TextStyle(fontSize: 16)),
                const SizedBox(width: 12),
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('alumni_users')
                        .snapshots(),
                    builder: (context, snap) {
                      if (!snap.hasData) return const Text("Loading...");

                      final batches = snap.data!.docs
                          .map((doc) {
                            final d = doc.data() as Map<String, dynamic>;
                            return d['batch']?.toString();
                          })
                          .where((b) => b != null && b!.isNotEmpty)
                          .cast<String>()
                          .toSet()
                          .toList();

                      batches.sort();
                      batches.insert(0, "All");

                      return DropdownButton<String>(
                        value: selectedBatch,
                        isExpanded: true,
                        items: batches
                            .map(
                              (b) => DropdownMenuItem(
                                value: b,
                                child: Text(b),
                              ),
                            )
                            .toList(),
                        onChanged: (v) {
                          setState(() => selectedBatch = v!);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          /// 👥 ALUMNI LIST
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('alumni_users')
                  .snapshots(),
              builder: (context, snap) {
                if (!snap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final alumniDocs = snap.data!.docs;

                final filtered = alumniDocs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final name =
                      (data['name'] ?? '').toString().toLowerCase();
                  final batch = (data['batch'] ?? '').toString();

                  if (!name.contains(searchQuery)) return false;
                  if (selectedBatch != "All" && batch != selectedBatch) {
                    return false;
                  }
                  return true;
                }).toList();

                if (filtered.isEmpty) {
                  return const Center(child: Text("No alumni found"));
                }

                return ListView.builder(
                  itemCount: filtered.length,
                  itemBuilder: (context, i) {
                    final data =
                        filtered[i].data() as Map<String, dynamic>;

                    final alumniId = filtered[i].id;
                    final name = data['name'] ?? 'Unknown';
                    final email = data['email'] ?? '';
                    final phone = data['phone'] ?? '';
                    final skills = data['skills'] ?? '';
                    final batch = data['batch']?.toString() ?? '';

                    int batchYear = int.tryParse(
                          batch.replaceAll(RegExp(r'[^0-9]'), ''),
                        ) ??
                        0;

                    final experience = batchYear > 0
                        ? DateTime.now().year - batchYear
                        : 0;

                    return Card(
                      margin: const EdgeInsets.all(10),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            /// 👤 ALUMNI INFO
                            ListTile(
                              leading: const CircleAvatar(
                                backgroundColor: Colors.blue,
                                child: Icon(Icons.person,
                                    color: Colors.white),
                              ),
                              title: Text("$name (Batch $batch)"),
                              subtitle: Text(
                                "Email: $email\n"
                                "Phone: $phone\n"
                                "Skills: $skills\n"
                                "Experience: $experience years",
                              ),
                            ),

                            const Divider(),

                            /// 💼 JOB POSTS BY THIS ALUMNI
                            StreamBuilder<QuerySnapshot>(
                              stream: FirebaseFirestore.instance
                                  .collection("jobs")
                                  .where("postedBy", isEqualTo: alumniId)
                                  .snapshots(),
                              builder: (context, jobSnap) {
                                if (!jobSnap.hasData ||
                                    jobSnap.data!.docs.isEmpty) {
                                  return const Text(
                                    "No job posts",
                                    style:
                                        TextStyle(color: Colors.grey),
                                  );
                                }

                                return Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: jobSnap.data!.docs.map((jobDoc) {
                                    final job =
                                        jobDoc.data() as Map<String, dynamic>;

                                    return Card(
                                      color: Colors.grey.shade100,
                                      margin: const EdgeInsets.symmetric(
                                          vertical: 6),
                                      child: ListTile(
                                        title:
                                            Text(job['title'] ?? 'No title'),
                                        subtitle: Text(
                                          "Skills: ${job['skillsRequired'] ?? ''}",
                                        ),
                                        trailing: IconButton(
                                          icon: const Icon(Icons.delete,
                                              color: Colors.red),
                                          onPressed: () =>
                                              deleteJob(jobDoc.id),
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
