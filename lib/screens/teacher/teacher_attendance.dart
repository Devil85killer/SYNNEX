import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TeacherAttendancePage extends StatefulWidget {
  const TeacherAttendancePage({super.key});

  @override
  State<TeacherAttendancePage> createState() => _TeacherAttendancePageState();
}

class _TeacherAttendancePageState extends State<TeacherAttendancePage> {
  String? selectedYear;
  String? selectedSection;

  final List<String> years = ["1st Year", "2nd Year", "3rd Year", "4th Year"];
  final List<String> sections = ["A", "B", "C"];

  Map<String, bool> attendance = {};

  Future<void> saveAttendance(String course, String branch) async {
    if (selectedYear == null || selectedSection == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Select Year & Section first")),
      );
      return;
    }

    final date = DateTime.now().toIso8601String().split("T")[0];

    final ref = FirebaseFirestore.instance
        .collection("attendance")
        .doc(course)
        .collection(branch)
        .doc(selectedYear)
        .collection(selectedSection!)
        .doc(date);

    for (var entry in attendance.entries) {
      await ref.collection("students").doc(entry.key).set({
        "present": entry.value,
        "timestamp": FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }

    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text("Attendance Saved")));
  }

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments;

    if (args == null || args is! Map) {
      return const Scaffold(
        body: Center(
          child: Text(
            "Teacher data missing ❌",
            style: TextStyle(fontSize: 20),
          ),
        ),
      );
    }

    final String course = args["course"];
    final String branch = args["branch"];

    return Scaffold(
      backgroundColor: Colors.blue.shade50,
      appBar: AppBar(
        title: const Text("Take Attendance"),
        backgroundColor: Colors.blue,
      ),
      body: Column(
        children: [
          const SizedBox(height: 10),

          DropdownButton(
            hint: const Text("Select Year"),
            value: selectedYear,
            items: years
                .map((y) => DropdownMenuItem(value: y, child: Text(y)))
                .toList(),
            onChanged: (v) {
              setState(() {
                selectedYear = v;
                attendance.clear();
              });
            },
          ),

          DropdownButton(
            hint: const Text("Select Section"),
            value: selectedSection,
            items: sections
                .map((s) =>
                    DropdownMenuItem(value: s, child: Text("Section $s")))
                .toList(),
            onChanged: (v) {
              setState(() {
                selectedSection = v;
                attendance.clear();
              });
            },
          ),

          if (selectedYear == null || selectedSection == null)
            const Padding(
              padding: EdgeInsets.all(20),
              child: Text(
                "Select Year & Section to load students",
                style: TextStyle(fontSize: 16),
              ),
            ),

          if (selectedYear != null && selectedSection != null)
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('students')
                    .where('course', isEqualTo: course)
                    .where('branch', isEqualTo: branch)
                    .where('year', isEqualTo: selectedYear)
                    .where('section', isEqualTo: selectedSection)
                    .snapshots(),
                builder: (context, snap) {
                  if (!snap.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final students = snap.data!.docs;

                  if (students.isEmpty) {
                    return const Center(
                        child: Text("No students found for this section."));
                  }

                  return ListView.builder(
                    itemCount: students.length,
                    itemBuilder: (context, i) {
                      final data = students[i].data() as Map<String, dynamic>;
                      final uid = students[i].id;

                      final name = data['name'] ?? "Unknown";
                      final rollNo = data['rollNo']?.toString() ?? "---";

                      attendance.putIfAbsent(uid, () => true);

                      return Card(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    rollNo,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.deepPurple,
                                    ),
                                  ),
                                  Text(
                                    name,
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),

                              Row(
                                children: [
                                  Text(
                                    attendance[uid]!
                                        ? "Present"
                                        : "Absent",
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color:
                                          attendance[uid]!
                                              ? Colors.green
                                              : Colors.red,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Switch(
                                    value: attendance[uid]!,
                                    onChanged: (v) {
                                      setState(() => attendance[uid] = v);
                                    },
                                  ),
                                ],
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

          ElevatedButton(
            onPressed: () => saveAttendance(course, branch),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              minimumSize: const Size(double.infinity, 50),
            ),
            child: const Text("Save Attendance"),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }
}
