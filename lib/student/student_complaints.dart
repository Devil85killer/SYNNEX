import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class StudentComplaintsPage extends StatefulWidget {
  const StudentComplaintsPage({super.key});

  @override
  State<StudentComplaintsPage> createState() => _StudentComplaintsPageState();
}

class _StudentComplaintsPageState extends State<StudentComplaintsPage> {
  final _complaintController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> _submitComplaint() async {
    final text = _complaintController.text.trim();
    if (text.isEmpty) return;

    await _firestore.collection('complaints').add({
      'title': 'Student Complaint',
      'description': text,
      'userRole': 'student',
      'status': 'open',
      'createdAt': FieldValue.serverTimestamp(),
    });

    _complaintController.clear();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Complaint submitted ✅")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Complaints / Feedback"),
        backgroundColor: Colors.blue.shade700,
      ),
      backgroundColor: Colors.blue.shade50,
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: _complaintController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: "Write your complaint or feedback",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _submitComplaint,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade700,
                minimumSize: const Size(double.infinity, 45),
              ),
              child: const Text("Submit"),
            ),
          ],
        ),
      ),
    );
  }
}
