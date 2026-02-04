import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'teacher_list.dart';
import 'student_year_list.dart';

class BranchListPage extends StatefulWidget {
  final String courseName;
  const BranchListPage({super.key, required this.courseName});

  @override
  State<BranchListPage> createState() => _BranchListPageState();
}

class _BranchListPageState extends State<BranchListPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _branchController = TextEditingController();

  // 🔹 Get total years of selected course
  Future<int> _getCourseYears() async {
    final courseDoc =
        await _firestore.collection('courses').doc(widget.courseName).get();
    if (courseDoc.exists) {
      final data = courseDoc.data() as Map<String, dynamic>;
      return (data['years'] ?? 0) as int;
    }
    return 0;
  }

  Future<void> _addBranch() async {
    if (_branchController.text.trim().isEmpty) return;
    final name = _branchController.text.trim();

    await _firestore
        .collection('courses')
        .doc(widget.courseName)
        .collection('branches')
        .doc(name)
        .set({
      'name': name,
      'createdAt': FieldValue.serverTimestamp(),
    });

    _branchController.clear();
  }

  Future<void> _deleteBranch(String name) async {
    await _firestore
        .collection('courses')
        .doc(widget.courseName)
        .collection('branches')
        .doc(name)
        .delete();
  }

  @override
  Widget build(BuildContext context) {
    final branchesRef = _firestore
        .collection('courses')
        .doc(widget.courseName)
        .collection('branches');

    return Scaffold(
      appBar: AppBar(
        title: Text("${widget.courseName} Branches"),
        backgroundColor: Colors.blueAccent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // 🔹 Add Branch Input Field
            TextField(
              controller: _branchController,
              decoration: InputDecoration(
                labelText: "Add Branch",
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.add, color: Colors.blue),
                  onPressed: _addBranch,
                ),
              ),
            ),
            const SizedBox(height: 20),

            // 🔹 Branch List
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: branchesRef.orderBy('name').snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final branches = snapshot.data!.docs;
                  if (branches.isEmpty) {
                    return const Center(child: Text("No branches found"));
                  }

                  return FutureBuilder<int>(
                    future: _getCourseYears(),
                    builder: (context, yearSnap) {
                      if (!yearSnap.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final totalYears = yearSnap.data ?? 0;

                      return ListView.builder(
                        itemCount: branches.length,
                        itemBuilder: (context, index) {
                          final data =
                              branches[index].data() as Map<String, dynamic>;
                          final branchName = data['name'] ?? '';

                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 8),
                            elevation: 4,
                            child: ListTile(
                              title: Text(
                                branchName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue,
                                ),
                              ),
                              subtitle: Row(
                                children: [
                                  // 🔸 View Teachers
                                  TextButton.icon(
                                    icon: const Icon(Icons.person,
                                        color: Colors.green),
                                    label: const Text("View Teachers"),
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => TeacherListPage(
                                            courseName: widget.courseName,
                                            branchName: branchName,
                                          ),
                                        ),
                                      );
                                    },
                                  ),

                                  // 🔸 View Students (goes to year list)
                                  TextButton.icon(
                                    icon: const Icon(Icons.group,
                                        color: Colors.deepPurple),
                                    label:
                                        const Text("View Year-wise Students"),
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => StudentYearListPage(
                                            courseName: widget.courseName,
                                            branchName: branchName,
                                            totalYears: totalYears,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete,
                                    color: Colors.redAccent),
                                tooltip: "Delete Branch",
                                onPressed: () => _deleteBranch(branchName),
                              ),
                            ),
                          );
                        },
                      );
                    },
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
