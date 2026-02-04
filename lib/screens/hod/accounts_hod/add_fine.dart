import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddFinePage extends StatefulWidget {
  const AddFinePage({super.key});

  @override
  State<AddFinePage> createState() => _AddFinePageState();
}

class _AddFinePageState extends State<AddFinePage> {
  final TextEditingController studentIdController = TextEditingController();
  final TextEditingController fineController = TextEditingController();

  Future<void> addFine() async {
    await FirebaseFirestore.instance
        .collection('student_fees')
        .doc(studentIdController.text.trim())
        .update({
      'fine': int.parse(fineController.text.trim()),
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Fine Added Successfully")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Add Fine"), backgroundColor: Colors.blue),

      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: studentIdController,
              decoration: const InputDecoration(labelText: "Student UID"),
            ),
            TextField(
              controller: fineController,
              decoration: const InputDecoration(labelText: "Fine Amount"),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: addFine,
              child: const Text("Add Fine"),
            )
          ],
        ),
      ),
    );
  }
}
