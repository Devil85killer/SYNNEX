import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:SYNNEX/screens/admin/manage_courses/branches/branch_list.dart'; // ✅ Correct import

class ManageCourses extends StatefulWidget {
  const ManageCourses({super.key});

  @override
  State<ManageCourses> createState() => _ManageCoursesState();
}

class _ManageCoursesState extends State<ManageCourses> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _courseController = TextEditingController();

  Future<void> _addCourse() async {
    if (_courseController.text.trim().isEmpty) return;
    final name = _courseController.text.trim();

    await _firestore.collection('courses').doc(name).set({
      'name': name,
      'years': 0, // default year count
      'createdAt': FieldValue.serverTimestamp(),
    });

    _courseController.clear();
  }

  Future<void> _deleteCourse(String name) async {
    await _firestore.collection('courses').doc(name).delete();
  }

  Future<void> _editYears(String courseName, int currentYears) async {
    final TextEditingController _yearController =
        TextEditingController(text: currentYears.toString());

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Set Years for $courseName"),
        content: TextField(
          controller: _yearController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: "Enter number of years",
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              final yearValue = int.tryParse(_yearController.text) ?? 0;
              await _firestore
                  .collection('courses')
                  .doc(courseName)
                  .update({'years': yearValue});
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
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _courseController,
                  decoration: InputDecoration(
                    labelText: "Add New Course",
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.add, color: Colors.blue),
                      onPressed: _addCourse,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream:
                  _firestore.collection('courses').orderBy('name').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snapshot.data?.docs ?? [];
                if (docs.isEmpty) {
                  return const Center(child: Text("No courses found"));
                }

                return ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    final courseName = data['name'] ?? '';
                    final years = data['years'] ?? 0;

                    return Card(
                      elevation: 4,
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      child: ListTile(
                        title: Text(
                          "$courseName (${years} yrs)",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.calendar_month,
                                  color: Colors.orange),
                              tooltip: "Edit Years",
                              onPressed: () => _editYears(courseName, years),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              tooltip: "Delete Course",
                              onPressed: () => _deleteCourse(courseName),
                            ),
                          ],
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  BranchListPage(courseName: courseName), // ✅ fixed
                            ),
                          );
                        },
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
