import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HODAttendancePage extends StatefulWidget {
  final String course;
  final String branch;

  const HODAttendancePage({
    super.key,
    required this.course,
    required this.branch,
  });

  @override
  State<HODAttendancePage> createState() => _HODAttendancePageState();
}

class _HODAttendancePageState extends State<HODAttendancePage> {
  final Map<String, bool> attendance = {};

  Future<void> _saveAttendance() async {
    final date = DateTime.now().toIso8601String().split("T")[0];

    final ref = FirebaseFirestore.instance
        .collection('attendance')
        .doc(widget.course)
        .collection(widget.branch)
        .doc(date);

    for (final entry in attendance.entries) {
      await ref.collection('students').doc(entry.key).set({
        "present": entry.value,
        "timestamp": FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }

    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text("Attendance saved")));
  }

  @override
  Widget build(BuildContext context) {
    final studentsRef = FirebaseFirestore.instance
        .collection('students')
        .where('course', isEqualTo: widget.course)
        .where('branch', isEqualTo: widget.branch)
        .orderBy('rollNo');

    return Scaffold(
      appBar: AppBar(
        title: const Text("Branch Attendance"),
        backgroundColor: Colors.blue,
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveAttendance,
          )
        ],
      ),
      backgroundColor: Colors.blue[50],
      body: StreamBuilder<QuerySnapshot>(
        stream: studentsRef.snapshots(),
        builder: (context, snap) {
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());

          final students = snap.data!.docs;

          return ListView.builder(
            itemCount: students.length,
            itemBuilder: (context, i) {
              final data = students[i].data() as Map<String, dynamic>;
              final uid = students[i].id;

              attendance.putIfAbsent(uid, () => true);

              return Card(
                child: ListTile(
                  leading: CircleAvatar(
                    child: Text(data['rollNo'].toString()),
                  ),
                  title: Text(data['name']),
                  subtitle: Text("Year: ${data['year']}"),
                  trailing: Switch(
                    value: attendance[uid]!,
                    onChanged: (v) => setState(() => attendance[uid] = v),
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
