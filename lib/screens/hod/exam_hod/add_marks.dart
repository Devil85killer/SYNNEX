import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddMarksPage extends StatefulWidget {
  const AddMarksPage({super.key});

  @override
  State<AddMarksPage> createState() => _AddMarksPageState();
}

class _AddMarksPageState extends State<AddMarksPage> {
  final idController = TextEditingController();
  final subController = TextEditingController();
  final marksController = TextEditingController();

  Future<void> saveMarks() async {
    await FirebaseFirestore.instance
        .collection("marks")
        .doc(idController.text.trim())
        .set({
      subController.text.trim(): int.parse(marksController.text.trim())
    }, SetOptions(merge: true));

    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text("Marks Updated")));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Add Marks"), backgroundColor: Colors.blue),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(children: [
          TextField(controller: idController, decoration: const InputDecoration(label: Text("Student UID"))),
          TextField(controller: subController, decoration: const InputDecoration(label: Text("Subject Name"))),
          TextField(
            controller: marksController,
            decoration: const InputDecoration(label: Text("Marks")),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 20),
          ElevatedButton(onPressed: saveMarks, child: const Text("Save Marks"))
        ]),
      ),
    );
  }
}
