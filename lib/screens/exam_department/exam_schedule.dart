import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ExamSchedulePage extends StatefulWidget {
  const ExamSchedulePage({Key? key}) : super(key: key);

  @override
  State<ExamSchedulePage> createState() => _ExamSchedulePageState();
}

class _ExamSchedulePageState extends State<ExamSchedulePage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool isHOD = false;
  bool loadingRole = true;

  @override
  void initState() {
    super.initState();
    _loadRole();
  }

  Future<void> _loadRole() async {
    final uid = _auth.currentUser!.uid;
    final doc =
        await _firestore.collection('exam_department').doc(uid).get();

    if (doc.exists) {
      isHOD = doc.data()?['isHOD'] == true;
    }
    setState(() => loadingRole = false);
  }

  void _addOrEditSchedule({DocumentSnapshot? doc}) {
    final subjectController =
        TextEditingController(text: doc?['subject'] ?? '');
    final dateController =
        TextEditingController(text: doc?['date'] ?? '');
    final timeController =
        TextEditingController(text: doc?['time'] ?? '');

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(doc == null ? "Add Exam Schedule" : "Edit Exam Schedule"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: subjectController,
              decoration: const InputDecoration(labelText: "Subject"),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: dateController,
              decoration:
                  const InputDecoration(labelText: "Date (DD/MM/YYYY)"),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: timeController,
              decoration:
                  const InputDecoration(labelText: "Time (e.g. 10:00 AM)"),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              if (subjectController.text.trim().isEmpty) return;

              final data = {
                'subject': subjectController.text.trim(),
                'date': dateController.text.trim(),
                'time': timeController.text.trim(),
                'createdAt': FieldValue.serverTimestamp(),
              };

              if (doc == null) {
                await _firestore.collection('exam_schedule').add(data);
              } else {
                await _firestore
                    .collection('exam_schedule')
                    .doc(doc.id)
                    .update(data);
              }

              Navigator.pop(context);
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Exam Schedule"),
        backgroundColor: Colors.orange,
        actions: [
          if (isHOD)
            IconButton(
              icon: const Icon(Icons.add),
              tooltip: "Add Schedule (HOD)",
              onPressed: () => _addOrEditSchedule(),
            ),
        ],
      ),
      body: loadingRole
          ? const Center(child: CircularProgressIndicator())
          : StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('exam_schedule')
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const Center(
                      child: CircularProgressIndicator());
                }

                if (!snapshot.hasData ||
                    snapshot.data!.docs.isEmpty) {
                  return const Center(
                      child: Text("No exam schedules found"));
                }

                final schedules = snapshot.data!.docs;

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: schedules.length,
                  itemBuilder: (context, index) {
                    final doc = schedules[index];
                    final data =
                        doc.data() as Map<String, dynamic>;

                    return Card(
                      elevation: 3,
                      margin:
                          const EdgeInsets.symmetric(vertical: 8),
                      child: ListTile(
                        title: Text(
                          data['subject'] ?? '',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          "Date: ${data['date'] ?? ''}\nTime: ${data['time'] ?? ''}",
                        ),
                        trailing: isHOD
                            ? Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit,
                                        color: Colors.orange),
                                    onPressed: () =>
                                        _addOrEditSchedule(doc: doc),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete,
                                        color: Colors.red),
                                    onPressed: () {
                                      _firestore
                                          .collection('exam_schedule')
                                          .doc(doc.id)
                                          .delete();
                                    },
                                  ),
                                ],
                              )
                            : null,
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}
