import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HODListPage extends StatelessWidget {
  const HODListPage({super.key});

  @override
  Widget build(BuildContext context) {
    final firestore = FirebaseFirestore.instance;

    return Scaffold(
      appBar: AppBar(
        title: const Text("All HODs"),
        backgroundColor: Colors.blueAccent,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: firestore.collection('teachers').where('isBranchHOD', isEqualTo: true).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final hods = snapshot.data!.docs;

          if (hods.isEmpty) {
            return const Center(child: Text("No HODs Assigned Yet"));
          }

          return ListView.builder(
            itemCount: hods.length,
            itemBuilder: (context, index) {
              final data = hods[index].data() as Map<String, dynamic>;
              final name = data['name'] ?? '';
              final email = data['email'] ?? '';
              final mobile = data['mobile'] ?? '';
              final course = data['course'] ?? '';
              final branch = data['branch'] ?? '';

              return Card(
                margin: const EdgeInsets.all(10),
                child: ListTile(
                  leading: const Icon(Icons.person, color: Colors.orange, size: 35),
                  title: Text(
                    "$name  👑",
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, color: Colors.blue),
                  ),
                  subtitle: Text(
                    "Course: $course\nBranch: $branch\nEmail: $email\nMobile: $mobile",
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
