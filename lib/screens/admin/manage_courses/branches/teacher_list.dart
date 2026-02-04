import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TeacherListPage extends StatefulWidget {
  final String courseName;
  final String branchName;

  const TeacherListPage({
    super.key,
    required this.courseName,
    required this.branchName,
  });

  @override
  State<TeacherListPage> createState() => _TeacherListPageState();
}

class _TeacherListPageState extends State<TeacherListPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 🔹 ASSIGN HOD
  Future<void> _assignHOD(String teacherId) async {
    final branchRef = _firestore
        .collection('courses')
        .doc(widget.courseName)
        .collection('branches')
        .doc(widget.branchName);

    final teachersRef = _firestore.collection('teachers');

    final branchDoc = await branchRef.get();
    String? currentHod = branchDoc.data()?['hodUid'];

    // remove old HOD
    if (currentHod != null && currentHod.isNotEmpty) {
      await teachersRef
          .doc(currentHod)
          .set({'isBranchHOD': false}, SetOptions(merge: true));
    }

    // set new HOD
    await branchRef.set({'hodUid': teacherId}, SetOptions(merge: true));

    await teachersRef.doc(teacherId).set({
      'isBranchHOD': true,
      'course': widget.courseName,
      'branch': widget.branchName,
    }, SetOptions(merge: true));

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("HOD assigned successfully")),
    );
  }

  // 🔹 REMOVE HOD
  Future<void> _removeHOD(String teacherId) async {
    final branchRef = _firestore
        .collection('courses')
        .doc(widget.courseName)
        .collection('branches')
        .doc(widget.branchName);

    final teachersRef = _firestore.collection('teachers');

    await branchRef.set({'hodUid': null}, SetOptions(merge: true));

    await teachersRef
        .doc(teacherId)
        .set({'isBranchHOD': false}, SetOptions(merge: true));

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("HOD removed successfully")),
    );
  }

  @override
  Widget build(BuildContext context) {
    final teachersRef = _firestore
        .collection('teachers')
        .where('course', isEqualTo: widget.courseName)
        .where('branch', isEqualTo: widget.branchName);

    return Scaffold(
      appBar: AppBar(
        title: Text("${widget.branchName} - Teachers"),
        backgroundColor: Colors.blueAccent,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: teachersRef.snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final teachers = snapshot.data!.docs;
          if (teachers.isEmpty) {
            return const Center(child: Text("No teachers found"));
          }

          return ListView.builder(
            itemCount: teachers.length,
            itemBuilder: (context, index) {
              final doc = teachers[index];
              final data = doc.data() as Map<String, dynamic>;

              final name = data['name'] ?? 'Unknown';
              final email = data['email'] ?? '';
              final mobile = data['mobile'] ?? '';
              final isHOD = data['isBranchHOD'] == true;

              return Card(
                margin: const EdgeInsets.all(10),
                child: ListTile(
                  leading: isHOD
                      ? const Icon(Icons.star,
                          color: Colors.orange, size: 35)
                      : const Icon(Icons.person,
                          color: Colors.green, size: 35),

                  title: Row(
                    children: [
                      Text(
                        name,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      if (isHOD)
                        const Padding(
                          padding: EdgeInsets.only(left: 8),
                          child: Text(
                            "👑 HOD",
                            style: TextStyle(
                              color: Colors.orange,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),

                  subtitle: Text("Email: $email\nMobile: $mobile"),

                  trailing: isHOD
                      ? ElevatedButton(
                          onPressed: () => _removeHOD(doc.id),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                          ),
                          child: const Text("Remove HOD"),
                        )
                      : ElevatedButton(
                          onPressed: () => _assignHOD(doc.id),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blueAccent,
                          ),
                          child: const Text("Make HOD"),
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
