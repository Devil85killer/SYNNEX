import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/department_sync_service.dart';

class AccountsAddStudentPage extends StatefulWidget {
  const AccountsAddStudentPage({Key? key}) : super(key: key);

  @override
  State<AccountsAddStudentPage> createState() => _AccountsAddStudentPageState();
}

class _AccountsAddStudentPageState extends State<AccountsAddStudentPage> {
  final DepartmentSyncService _syncService = DepartmentSyncService();

  String? _selectedStudentUid;
  Map<String, dynamic>? _selectedStudentData;
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Add Student to Accounts"),
        backgroundColor: Colors.teal,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('admin_students')
                  .orderBy('name')
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const CircularProgressIndicator();
                }

                final docs = snapshot.data!.docs;
                return DropdownButtonFormField<String>(
                  hint: const Text("Select Student"),
                  value: _selectedStudentUid,
                  items: docs.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    return DropdownMenuItem(
                      value: doc.id,
                      child: Text("${data['name']} - ${data['course']}"),
                    );
                  }).toList(),
                  onChanged: (uid) {
                    final doc =
                        docs.firstWhere((element) => element.id == uid);
                    setState(() {
                      _selectedStudentUid = uid;
                      _selectedStudentData =
                          doc.data() as Map<String, dynamic>;
                    });
                  },
                );
              },
            ),
            const SizedBox(height: 20),
            if (_selectedStudentData != null)
              Text(
                "Branch: ${_selectedStudentData!['branch']} | Year: ${_selectedStudentData!['year']}",
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: (_selectedStudentUid == null || _loading)
                  ? null
                  : () async {
                      setState(() => _loading = true);
                      await _syncService.addStudentToDepartment(
                        studentUid: _selectedStudentUid!,
                        department: 'accounts',
                      );
                      setState(() => _loading = false);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text("Student added to Accounts")),
                      );
                    },
              child: _loading
                  ? const CircularProgressIndicator()
                  : const Text("Add to Accounts"),
            ),
          ],
        ),
      ),
    );
  }
}
