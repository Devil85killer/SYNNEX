import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FeeStructurePage extends StatefulWidget {
  const FeeStructurePage({super.key});

  @override
  State<FeeStructurePage> createState() => _FeeStructurePageState();
}

class _FeeStructurePageState extends State<FeeStructurePage> {
  final TextEditingController courseController = TextEditingController();
  final TextEditingController feeController = TextEditingController();

  Future<void> saveFee() async {
    await FirebaseFirestore.instance
        .collection('fee_structure')
        .doc(courseController.text.trim())
        .set({
      'course': courseController.text.trim(),
      'fee': int.parse(feeController.text.trim()),
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Fee Structure Updated")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Fee Structure"), backgroundColor: Colors.blue),

      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: courseController,
              decoration: const InputDecoration(label: Text("Course Name")),
            ),
            TextField(
              controller: feeController,
              decoration: const InputDecoration(label: Text("Total Fee")),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: saveFee,
              child: const Text("Save"),
            )
          ],
        ),
      ),
    );
  }
}
