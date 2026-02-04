import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ExamResultsPage extends StatefulWidget {
  const ExamResultsPage({Key? key}) : super(key: key);

  @override
  State<ExamResultsPage> createState() => _ExamResultsPageState();
}

class _ExamResultsPageState extends State<ExamResultsPage> {
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  bool isHOD = false;
  bool loadingRole = true;

  String? course;
  String? branch;
  String? year;
  String? section;

  final years = ['1st Year', '2nd Year', '3rd Year', '4th Year'];
  final sections = ['A', 'B', 'C'];

  @override
  void initState() {
    super.initState();
    _loadRole();
  }

  Future<void> _loadRole() async {
    final uid = _auth.currentUser!.uid;
    final doc = await _db.collection('exam_department').doc(uid).get();
    isHOD = doc.data()?['isHOD'] == true;
    setState(() => loadingRole = false);
  }

  /// 🔹 ADD / EDIT MARKS
  void _markDialog({
    required Map<String, dynamic> student,
    String? docId,
    String? subject,
    int? marks,
  }) {
    final subjectCtrl = TextEditingController(text: subject ?? '');
    final marksCtrl =
        TextEditingController(text: marks?.toString() ?? '');

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(
            docId == null ? "Add Marks" : "Edit Marks"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("${student['name']} (${student['rollNo']})"),
            const SizedBox(height: 10),
            TextField(
              controller: subjectCtrl,
              decoration:
                  const InputDecoration(labelText: "Subject"),
            ),
            TextField(
              controller: marksCtrl,
              keyboardType: TextInputType.number,
              decoration:
                  const InputDecoration(labelText: "Marks"),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              final data = {
                'studentId': student['uid'],
                'name': student['name'],
                'rollNo': student['rollNo'],
                'course': student['course'],
                'branch': student['branch'],
                'year': student['year'],
                'section': student['section'],
                'subject': subjectCtrl.text.trim(),
                'marks': int.tryParse(marksCtrl.text) ?? 0,
                'published': false,
                'createdAt': FieldValue.serverTimestamp(),
              };

              if (docId == null) {
                await _db.collection('exam_results').add(data);
              } else {
                await _db
                    .collection('exam_results')
                    .doc(docId)
                    .update(data);
              }

              Navigator.pop(context);
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  /// 🔹 DELETE MARK
  Future<void> _deleteMark(String id) async {
    await _db.collection('exam_results').doc(id).delete();
  }

  /// 🔹 PUBLISH (HOD)
  Future<void> _publish(String id) async {
    await _db
        .collection('exam_results')
        .doc(id)
        .update({'published': true});
  }

  @override
  Widget build(BuildContext context) {
    if (loadingRole) {
      return const Scaffold(
          body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Exam Results"),
        backgroundColor: Colors.orange,
      ),
      body: Column(
        children: [
          /// 🔹 FILTERS
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                StreamBuilder<QuerySnapshot>(
                  stream: _db.collection('courses').snapshots(),
                  builder: (_, s) {
                    if (!s.hasData) return const SizedBox();
                    return DropdownButtonFormField(
                      value: course,
                      items: s.data!.docs
                          .map((d) => DropdownMenuItem(
                                value: d.id,
                                child: Text(d.id),
                              ))
                          .toList(),
                      onChanged: (v) =>
                          setState(() => course = v),
                      decoration:
                          const InputDecoration(labelText: "Course"),
                    );
                  },
                ),
                if (course != null)
                  StreamBuilder<QuerySnapshot>(
                    stream: _db
                        .collection('courses')
                        .doc(course)
                        .collection('branches')
                        .snapshots(),
                    builder: (_, s) {
                      if (!s.hasData) return const SizedBox();
                      return DropdownButtonFormField(
                        value: branch,
                        items: s.data!.docs
                            .map((d) => DropdownMenuItem(
                                  value: d.id,
                                  child: Text(d.id),
                                ))
                            .toList(),
                        onChanged: (v) =>
                            setState(() => branch = v),
                        decoration:
                            const InputDecoration(labelText: "Branch"),
                      );
                    },
                  ),
                DropdownButtonFormField(
                  value: year,
                  items: years
                      .map((y) =>
                          DropdownMenuItem(value: y, child: Text(y)))
                      .toList(),
                  onChanged: (v) => setState(() => year = v),
                  decoration:
                      const InputDecoration(labelText: "Year"),
                ),
                DropdownButtonFormField(
                  value: section,
                  items: sections
                      .map((s) => DropdownMenuItem(
                          value: s, child: Text("Section $s")))
                      .toList(),
                  onChanged: (v) =>
                      setState(() => section = v),
                  decoration:
                      const InputDecoration(labelText: "Section"),
                ),
              ],
            ),
          ),

          /// 🔹 RESULT LIST
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _db
                  .collection('exam_results')
                  .where('course', isEqualTo: course)
                  .where('branch', isEqualTo: branch)
                  .where('year', isEqualTo: year)
                  .where('section', isEqualTo: section)
                  .snapshots(),
              builder: (_, s) {
                if (!s.hasData) {
                  return const Center(
                      child: CircularProgressIndicator());
                }

                if (s.data!.docs.isEmpty) {
                  return const Center(
                      child: Text("No marks uploaded"));
                }

                return ListView(
                  children: s.data!.docs.map((doc) {
                    final d =
                        doc.data() as Map<String, dynamic>;

                    return Card(
                      child: ListTile(
                        title: Text(
                            "${d['name']} (${d['rollNo']})"),
                        subtitle: Text(
                            "${d['subject']} : ${d['marks']}"),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon:
                                  const Icon(Icons.edit),
                              onPressed: () =>
                                  _markDialog(
                                student: d,
                                docId: doc.id,
                                subject: d['subject'],
                                marks: d['marks'],
                              ),
                            ),
                            IconButton(
                              icon:
                                  const Icon(Icons.delete),
                              onPressed: () =>
                                  _deleteMark(doc.id),
                            ),
                            if (isHOD &&
                                d['published'] != true)
                              IconButton(
                                icon: const Icon(
                                    Icons.publish,
                                    color: Colors.green),
                                onPressed: () =>
                                    _publish(doc.id),
                              ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
