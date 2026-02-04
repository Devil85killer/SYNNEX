import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/department_sync_service.dart';

class LibraryAddStudentPage extends StatefulWidget {
  const LibraryAddStudentPage({Key? key}) : super(key: key);

  @override
  State<LibraryAddStudentPage> createState() => _LibraryAddStudentPageState();
}

class _LibraryAddStudentPageState extends State<LibraryAddStudentPage> {
  final DepartmentSyncService _syncService = DepartmentSyncService();

  String? _selectedStudentUid;
  Map<String, dynamic>? _selectedStudentData;
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Add Student to Library"),
        backgroundColor: Colors.purple,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Select Student (From Admin)",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            /// 🔹 ADMIN STUDENTS LIST
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('admin_students')
                  .orderBy('name')
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const CircularProgressIndicator();
                }

                final docs = snapshot.data!.docs;
                if (docs.isEmpty) {
                  return const Text("No students found in Admin");
                }

                return DropdownButtonFormField<String>(
                  value: _selectedStudentUid,
                  hint: const Text("Choose Student"),
                  items: docs.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    return DropdownMenuItem(
                      value: doc.id,
                      child: Text(
                        "${data['name']} - ${data['course']} (${data['branch']})",
                      ),
                    );
                  }).toList(),
                  onChanged: (uid) {
                    final doc =
                        docs.firstWhere((element) => element.id == uid);
                    setState(() {
                      _selectedStudentUid = uid;
                      _selectedStudentData =
                          doc.data() as Map<String, dynamic>;
                    });
                  },
                );
              },
            ),

            const SizedBox(height: 20),

            /// 🔹 PREVIEW STUDENT DATA
            if (_selectedStudentData != null) ...[
              const Text(
                "Student Details",
                style:
                    TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              _infoRow("Name", _selectedStudentData!['name']),
              _infoRow("Course", _selectedStudentData!['course']),
              _infoRow("Branch", _selectedStudentData!['branch']),
              _infoRow("Year", _selectedStudentData!['year']),
              const SizedBox(height: 30),
            ],

            /// 🔹 ADD BUTTON
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: (_selectedStudentUid == null || _loading)
                    ? null
                    : () async {
                        setState(() => _loading = true);

                        try {
                          await _syncService.addStudentToDepartment(
                            studentUid: _selectedStudentUid!,
                            department: 'library',
                          );

                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content:
                                  Text("Student added to Library successfully"),
                            ),
                          );

                          setState(() {
                            _selectedStudentUid = null;
                            _selectedStudentData = null;
                          });
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text("Error: $e")),
                          );
                        } finally {
                          setState(() => _loading = false);
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: _loading
                    ? const CircularProgressIndicator(
                        color: Colors.white,
                      )
                    : const Text(
                        "Add Student to Library",
                        style: TextStyle(fontSize: 16),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 🔹 INFO ROW WIDGET
  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(
            "$label: ",
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
