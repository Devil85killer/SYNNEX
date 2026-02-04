import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class TeacherBooksPage extends StatefulWidget {
  const TeacherBooksPage({Key? key}) : super(key: key);

  @override
  State<TeacherBooksPage> createState() => _TeacherBooksPageState();
}

class _TeacherBooksPageState extends State<TeacherBooksPage> {
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  bool isHOD = false;
  String? course;
  String? branch;

  @override
  void initState() {
    super.initState();
    _loadRole();
  }

  Future<void> _loadRole() async {
    final uid = _auth.currentUser!.uid;
    final teacherDoc = await _db.collection('teachers').doc(uid).get();

    if (teacherDoc.exists) {
      final data = teacherDoc.data()!;
      isHOD = data['isBranchHOD'] == true;
      course = data['course'];
      branch = data['branch'];
    }
    setState(() {});
  }

  Widget _statusWidget(bool returned) {
    return returned
        ? const Text(
            "Returned",
            style: TextStyle(
                color: Colors.green, fontWeight: FontWeight.bold),
          )
        : const Text(
            "Issued",
            style:
                TextStyle(color: Colors.orange, fontWeight: FontWeight.bold),
          );
  }

  Widget _issuedList(Query query) {
    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data!.docs;
        if (docs.isEmpty) {
          return const Center(child: Text("No issued books"));
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final d = docs[index].data() as Map<String, dynamic>;
            return Card(
              margin: const EdgeInsets.symmetric(vertical: 6),
              child: ListTile(
                leading:
                    const Icon(Icons.menu_book, color: Colors.blue),
                title: Text(d['bookTitle'] ?? ''),
                subtitle: Text(
                  "Name: ${d['name']}\n"
                  "Type: ${d['userType']}\n"
                  "Issued On: ${d['issuedAt'] != null ? (d['issuedAt'] as Timestamp).toDate().toString().substring(0, 10) : '-'}",
                ),
                trailing: _statusWidget(d['returned'] == true),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final uid = _auth.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Issued Books"),
        backgroundColor: Colors.blue,
      ),
      body: isHOD == false && course == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  /// 🔹 MY ISSUED BOOKS
                  const Text(
                    "My Issued Books",
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  _issuedList(
                    _db
                        .collection('library_issued_books')
                        .where('userType', isEqualTo: 'Teacher')
                        .where('userId', isEqualTo: uid),
                  ),

                  /// 🔹 BRANCH ISSUED BOOKS (ONLY HOD)
                  if (isHOD) ...[
                    const SizedBox(height: 20),
                    const Divider(),
                    const SizedBox(height: 10),
                    const Text(
                      "Branch Issued Books (Teachers & Students)",
                      style: TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    _issuedList(
                      _db
                          .collection('library_issued_books')
                          .where('course', isEqualTo: course)
                          .where('branch', isEqualTo: branch),
                    ),
                  ],
                ],
              ),
            ),
    );
  }
}
