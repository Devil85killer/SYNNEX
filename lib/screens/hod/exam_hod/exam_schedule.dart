import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ExamSchedulePage extends StatefulWidget {
  const ExamSchedulePage({super.key});

  @override
  State<ExamSchedulePage> createState() => _ExamSchedulePageState();
}

class _ExamSchedulePageState extends State<ExamSchedulePage> {
  final subjectController = TextEditingController();
  final dateController = TextEditingController();
  final timeController = TextEditingController();

  Future<void> saveSchedule() async {
    await FirebaseFirestore.instance.collection("exam_schedule").add({
      "subject": subjectController.text,
      "date": dateController.text,
      "time": timeController.text,
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Schedule Added")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Exam Schedule"), backgroundColor: Colors.blue),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(children: [
          TextField(controller: subjectController, decoration: const InputDecoration(labelText: "Subject")),
          TextField(controller: dateController, decoration: const InputDecoration(labelText: "Date (DD/MM/YYYY)")),
          TextField(controller: timeController, decoration: const InputDecoration(labelText: "Time")),
          const SizedBox(height: 20),
          ElevatedButton(onPressed: saveSchedule, child: const Text("Save"))
        ]),
      ),
    );
  }
}
