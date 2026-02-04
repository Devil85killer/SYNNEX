// ======================= EXAM REPORTS PAGE (VIEW – WITH NAME SHOWING) =======================
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ExamReportsPage extends StatefulWidget {
  const ExamReportsPage({Key? key}) : super(key: key);

  @override
  State<ExamReportsPage> createState() => _ExamReportsPageState();
}

class _ExamReportsPageState extends State<ExamReportsPage> {
  final _db = FirebaseFirestore.instance;

  String? course;
  String? branch;
  String? year;
  String? section;

  final years = ['1st Year', '2nd Year', '3rd Year', '4th Year'];
  final sections = ['A', 'B', 'C'];

  @override
  Widget build(BuildContext context) {
    Query q = _db
        .collection('exam_results')
        .where('published', isEqualTo: true);

    if (course != null) q = q.where('course', isEqualTo: course);
    if (branch != null) q = q.where('branch', isEqualTo: branch);
    if (year != null) q = q.where('year', isEqualTo: year);
    if (section != null) q = q.where('section', isEqualTo: section);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Exam Reports"),
        backgroundColor: Colors.orange,
      ),
      body: Column(
        children: [
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
                      onChanged: (v) {
                        setState(() {
                          course = v;
                          branch = null;
                          year = null;
                          section = null;
                        });
                      },
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
                        onChanged: (v) {
                          setState(() {
                            branch = v;
                            year = null;
                            section = null;
                          });
                        },
                        decoration:
                            const InputDecoration(labelText: "Branch"),
                      );
                    },
                  ),
                if (branch != null)
                  DropdownButtonFormField(
                    value: year,
                    items: years
                        .map((y) =>
                            DropdownMenuItem(value: y, child: Text(y)))
                        .toList(),
                    onChanged: (v) {
                      setState(() {
                        year = v;
                        section = null;
                      });
                    },
                    decoration:
                        const InputDecoration(labelText: "Year"),
                  ),
                if (year != null)
                  DropdownButtonFormField(
                    value: section,
                    items: sections
                        .map((s) => DropdownMenuItem(
                            value: s, child: Text("Section $s")))
                        .toList(),
                    onChanged: (v) => setState(() => section = v),
                    decoration:
                        const InputDecoration(labelText: "Section"),
                  ),
              ],
            ),
          ),
          Expanded(
            child: (course == null ||
                    branch == null ||
                    year == null ||
                    section == null)
                ? const Center(child: Text("Select all filters"))
                : StreamBuilder<QuerySnapshot>(
                    stream: q.snapshots(),
                    builder: (_, s) {
                      if (!s.hasData) {
                        return const Center(
                            child: CircularProgressIndicator());
                      }
                      if (s.data!.docs.isEmpty) {
                        return const Center(
                            child: Text("No published results"));
                      }

                      return ListView(
                        children: s.data!.docs.map((doc) {
                          final d =
                              doc.data() as Map<String, dynamic>;
                          return Card(
                            child: ListTile(
                              title: Text(
                                "${d['studentName']} (${d['rollNo']})",
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
                              ),
                              subtitle: Text(
                                  "${d['subject']} : ${d['marks']}"),
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
