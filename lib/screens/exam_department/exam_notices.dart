import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ExamNoticesPage extends StatefulWidget {
  const ExamNoticesPage({Key? key}) : super(key: key);

  @override
  State<ExamNoticesPage> createState() => _ExamNoticesPageState();
}

class _ExamNoticesPageState extends State<ExamNoticesPage> {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

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

  void _addNoticeDialog() {
    final titleController = TextEditingController();
    final descController = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Add Exam Notice"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: "Title"),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: descController,
              maxLines: 3,
              decoration: const InputDecoration(labelText: "Description"),
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
              if (titleController.text.trim().isEmpty) return;

              await _firestore.collection('exam_notices').add({
                'title': titleController.text.trim(),
                'description': descController.text.trim(),
                'createdAt': FieldValue.serverTimestamp(),
              });

              Navigator.pop(context);
            },
            child: const Text("Publish"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Exam Notices"),
        backgroundColor: Colors.orange,
        actions: [
          if (isHOD)
            IconButton(
              tooltip: "Add Notice (HOD)",
              icon: const Icon(Icons.add),
              onPressed: _addNoticeDialog,
            ),
        ],
      ),
      body: loadingRole
          ? const Center(child: CircularProgressIndicator())
          : StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('exam_notices')
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
                      child: Text("No notices available"));
                }

                final notices = snapshot.data!.docs;

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: notices.length,
                  itemBuilder: (context, index) {
                    final data =
                        notices[index].data() as Map<String, dynamic>;

                    return Card(
                      elevation: 3,
                      margin:
                          const EdgeInsets.symmetric(vertical: 8),
                      child: ListTile(
                        title: Text(
                          data['title'] ?? '',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold),
                        ),
                        subtitle:
                            Text(data['description'] ?? ''),
                        trailing: isHOD
                            ? IconButton(
                                icon: const Icon(Icons.delete,
                                    color: Colors.red),
                                onPressed: () {
                                  _firestore
                                      .collection('exam_notices')
                                      .doc(notices[index].id)
                                      .delete();
                                },
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
