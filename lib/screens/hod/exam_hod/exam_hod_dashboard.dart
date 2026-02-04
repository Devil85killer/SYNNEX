import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'add_marks.dart';
import 'exam_schedule.dart';
import 'report_generation.dart';

class ExamHODDashboard extends StatelessWidget {
  const ExamHODDashboard({super.key});

  Future<void> _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushNamedAndRemoveUntil(context, '/hod_login', (route) => false);
  }

  Widget card({required IconData icon, required String text, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        color: Colors.blue.shade50,
        elevation: 4,
        child: Center(
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(icon, size: 40, color: Colors.blue),
            const SizedBox(height: 10),
            Text(text, textAlign: TextAlign.center, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600))
          ]),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Exam HOD Dashboard"),
        backgroundColor: Colors.blue,
        actions: [
          IconButton(onPressed: () => _logout(context), icon: const Icon(Icons.logout))
        ],
      ),
      body: GridView.count(
        padding: const EdgeInsets.all(16),
        crossAxisCount: 2,
        mainAxisSpacing: 20,
        crossAxisSpacing: 20,
        children: [
          card(icon: Icons.edit, text: "Add / Update Marks", onTap: () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const AddMarksPage()));
          }),
          card(icon: Icons.schedule, text: "Exam Schedule", onTap: () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const ExamSchedulePage()));
          }),
          card(icon: Icons.receipt_long, text: "Generate Reports", onTap: () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const ReportGenerationPage()));
          }),
        ],
      ),
    );
  }
}
