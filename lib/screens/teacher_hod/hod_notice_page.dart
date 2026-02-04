import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HODNoticePage extends StatefulWidget {
  final String course;
  final String branch;

  const HODNoticePage({
    super.key,
    required this.course,
    required this.branch,
  });

  @override
  State<HODNoticePage> createState() => _HODNoticePageState();
}

class _HODNoticePageState extends State<HODNoticePage> {
  final _title = TextEditingController();
  final _message = TextEditingController();

  Future<void> _uploadNotice() async {
    if (_title.text.isEmpty || _message.text.isEmpty) return;

    await FirebaseFirestore.instance
        .collection('notices')
        .add({
      'title': _title.text.trim(),
      'message': _message.text.trim(),
      'course': widget.course,
      'branch': widget.branch,
      'createdAt': FieldValue.serverTimestamp(),
    });

    _title.clear();
    _message.clear();

    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text("Notice posted successfully")));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Upload Notice"),
        backgroundColor: Colors.blue,
      ),
      backgroundColor: Colors.blue[50],
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _title,
              decoration: const InputDecoration(
                labelText: "Notice Title",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _message,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: "Notice Message",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _uploadNotice,
              icon: const Icon(Icons.upload),
              label: const Text("Post Notice"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                minimumSize: const Size(double.infinity, 50),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
