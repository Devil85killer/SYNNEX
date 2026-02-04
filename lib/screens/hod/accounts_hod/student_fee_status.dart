import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class StudentFeeStatusPage extends StatelessWidget {
  const StudentFeeStatusPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Student Fee Status"),
        backgroundColor: Colors.blue,
      ),

      body: StreamBuilder(
        stream: FirebaseFirestore.instance.collection('student_fees').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final students = snapshot.data!.docs;

          return ListView.builder(
            itemCount: students.length,
            itemBuilder: (context, index) {
              final data = students[index].data() as Map<String, dynamic>;

              return Card(
                margin: const EdgeInsets.all(12),
                child: ListTile(
                  title: Text(data['name'] ?? ''),
                  subtitle: Text(
                      "Paid: ₹${data['paid']}\nPending: ₹${data['pending']}\nFine: ₹${data['fine']}"),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
