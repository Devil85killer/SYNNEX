import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ReportGenerationPage extends StatelessWidget {
  const ReportGenerationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Reports"), backgroundColor: Colors.blue),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance.collection("marks").snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final data = snapshot.data!.docs;

          return ListView.builder(
            itemCount: data.length,
            itemBuilder: (context, index) {
              final marks = data[index].data() as Map<String, dynamic>;

              return Card(
                margin: const EdgeInsets.all(12),
                child: ListTile(
                  title: Text("Student: ${data[index].id}"),
                  subtitle: Text(marks.toString()),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
