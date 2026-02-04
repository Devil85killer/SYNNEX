import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HODRoutineManager extends StatefulWidget {
  final String course;
  final String branch;

  const HODRoutineManager({
    super.key,
    required this.course,
    required this.branch,
  });

  @override
  State<HODRoutineManager> createState() => _HODRoutineManagerState();
}

class _HODRoutineManagerState extends State<HODRoutineManager> {
  final List<String> days = ["Monday","Tuesday","Wednesday","Thursday","Friday","Saturday"];
  String? _selectedDay;

  final _subject = TextEditingController();
  final _time = TextEditingController();

  Future<void> _addRoutine() async {
    if (_selectedDay == null || _subject.text.isEmpty || _time.text.isEmpty) return;

    await FirebaseFirestore.instance
        .collection('routines')
        .doc(widget.course)
        .collection(widget.branch)
        .doc(_selectedDay)
        .collection("classes")
        .add({
      "subject": _subject.text.trim(),
      "time": _time.text.trim(),
      "day": _selectedDay,
    });

    _subject.clear();
    _time.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Routine Manager"),
        backgroundColor: Colors.blue,
      ),
      backgroundColor: Colors.blue[50],
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            DropdownButtonFormField<String>(
              value: _selectedDay,
              items: days.map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
              onChanged: (v) => setState(() => _selectedDay = v),
              decoration: const InputDecoration(
                labelText: "Select Day",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _subject,
              decoration: const InputDecoration(
                labelText: "Subject Name",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _time,
              decoration: const InputDecoration(
                labelText: "Time (ex: 10:00 - 11:00)",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _addRoutine,
              icon: const Icon(Icons.add),
              label: const Text("Add Class"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                minimumSize: const Size(double.infinity, 50),
              ),
            ),
            const SizedBox(height: 12),

            // Routine list
            Expanded(
              child: _selectedDay == null
                  ? const Center(child: Text("Select a day to view routine"))
                  : StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('routines')
                          .doc(widget.course)
                          .collection(widget.branch)
                          .doc(_selectedDay)
                          .collection("classes")
                          .snapshots(),
                      builder: (context, snap) {
                        if (!snap.hasData) return const Center(child: CircularProgressIndicator());

                        final data = snap.data!.docs;
                        if (data.isEmpty) {
                          return const Center(child: Text("No classes added"));
                        }

                        return ListView.builder(
                          itemCount: data.length,
                          itemBuilder: (context, index) {
                            final item = data[index].data() as Map<String, dynamic>;
                            return Card(
                              child: ListTile(
                                title: Text(item['subject']),
                                subtitle: Text(item['time']),
                                trailing: IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () =>
                                      data[index].reference.delete(),
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
            )
          ],
        ),
      ),
    );
  }
}
