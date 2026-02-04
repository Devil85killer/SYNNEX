import 'package:flutter/material.dart';

class AttendanceManagement extends StatefulWidget {
  const AttendanceManagement({super.key});

  @override
  State<AttendanceManagement> createState() => _AttendanceManagementState();
}

class _AttendanceManagementState extends State<AttendanceManagement> {
  final List<Map<String, dynamic>> _attendance = [];

  final _studentController = TextEditingController();
  bool _isPresent = false;

  void _addAttendance() {
    if (_studentController.text.isEmpty) return;
    setState(() {
      _attendance.add({
        'student': _studentController.text,
        'present': _isPresent,
      });
      _studentController.clear();
    });
  }

  void _deleteEntry(int index) {
    setState(() {
      _attendance.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              "Mark Attendance",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _studentController,
                    decoration: const InputDecoration(
                      labelText: "Student Roll No",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Checkbox(
                  value: _isPresent,
                  onChanged: (val) => setState(() => _isPresent = val ?? false),
                ),
                const Text("Present"),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: _addAttendance,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                  child: const Text("Add"),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: _attendance.length,
                itemBuilder: (context, index) {
                  final entry = _attendance[index];
                  return Card(
                    child: ListTile(
                      title: Text(entry['student']),
                      subtitle: Text(entry['present'] ? "Present" : "Absent"),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _deleteEntry(index),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
