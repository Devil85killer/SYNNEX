import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class DepartmentStaffPage extends StatefulWidget {
  final String departmentName;
  final String collectionName;

  const DepartmentStaffPage({
    super.key,
    required this.departmentName,
    required this.collectionName,
  });

  @override
  State<DepartmentStaffPage> createState() => _DepartmentStaffPageState();
}

class _DepartmentStaffPageState extends State<DepartmentStaffPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 🔹 Assign HOD
  Future<void> _assignHOD(String uid) async {
    await _firestore
        .collection(widget.collectionName)
        .doc(uid)
        .set({'isHOD': true}, SetOptions(merge: true));

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("HOD assigned successfully!")),
    );
  }

  // 🔹 Delete Staff
  Future<void> _deleteStaff(String uid) async {
    await _firestore.collection(widget.collectionName).doc(uid).delete();

    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text("Staff removed!")));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("${widget.departmentName} Staff"),
        backgroundColor: Colors.blueAccent,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore.collection(widget.collectionName).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final staff = snapshot.data!.docs;

          if (staff.isEmpty) {
            return const Center(child: Text("No staff found"));
          }

          return ListView.builder(
            itemCount: staff.length,
            itemBuilder: (context, index) {
              final data =
                  staff[index].data() as Map<String, dynamic>;

              final name = data['name'] ?? "Unknown";
              final email = data['email'] ?? "";
              final isHOD = data['isHOD'] == true;
              final dob = data['dob'] ?? "";
              final blood = data['bloodGroup'] ?? "";
              final uid = staff[index].id;

              return Card(
                margin: const EdgeInsets.all(12),
                child: ListTile(
                  leading: Icon(
                    Icons.person,
                    color: isHOD ? Colors.green : Colors.blue,
                  ),
                  title: Text(name),
                  subtitle: Text("Email: $email\nDOB: $dob\nBlood: $blood"),
                  isThreeLine: true,
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // HOD Button
                      isHOD
                          ? const Text(
                              "HOD 👑",
                              style: TextStyle(
                                color: Colors.green,
                                fontWeight: FontWeight.bold,
                              ),
                            )
                          : ElevatedButton(
                              onPressed: () => _assignHOD(uid),
                              child: const Text("Make HOD"),
                            ),
                      const SizedBox(width: 10),

                      // Delete Button
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _deleteStaff(uid),
                      ),
                    ],
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
