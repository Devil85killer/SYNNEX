import 'package:flutter/material.dart';

class RoutineManagement extends StatefulWidget {
  const RoutineManagement({super.key});

  @override
  State<RoutineManagement> createState() => _RoutineManagementState();
}

class _RoutineManagementState extends State<RoutineManagement> {
  final List<Map<String, String>> _routine = [];

  final _subjectController = TextEditingController();
  final _dayController = TextEditingController();
  final _timeController = TextEditingController();

  void _addRoutine() {
    if (_subjectController.text.isEmpty ||
        _dayController.text.isEmpty ||
        _timeController.text.isEmpty) return;

    setState(() {
      _routine.add({
        'subject': _subjectController.text,
        'day': _dayController.text,
        'time': _timeController.text,
      });
    });

    _subjectController.clear();
    _dayController.clear();
    _timeController.clear();
  }

  void _deleteRoutine(int index) {
    setState(() {
      _routine.removeAt(index);
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
              "Add Class Routine",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _subjectController,
                    decoration: const InputDecoration(
                      labelText: "Subject",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _dayController,
                    decoration: const InputDecoration(
                      labelText: "Day",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _timeController,
                    decoration: const InputDecoration(
                      labelText: "Time",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: _addRoutine,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                  child: const Text("Add"),
                )
              ],
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: _routine.length,
                itemBuilder: (context, index) {
                  final r = _routine[index];
                  return Card(
                    child: ListTile(
                      title: Text("${r['subject']} - ${r['day']} (${r['time']})"),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _deleteRoutine(index),
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
