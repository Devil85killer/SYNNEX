import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LibraryProfilePage extends StatefulWidget {
  const LibraryProfilePage({Key? key}) : super(key: key);

  @override
  State<LibraryProfilePage> createState() => _LibraryProfilePageState();
}

class _LibraryProfilePageState extends State<LibraryProfilePage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String name = '';
  String email = '';
  String mobile = '';
  bool isHOD = false;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final uid = _auth.currentUser!.uid;
    final authEmail = _auth.currentUser!.email ?? '';

    final doc =
        await _firestore.collection('library_department').doc(uid).get();

    if (doc.exists) {
      final data = doc.data()!;
      name = data['name'] ?? '';
      mobile = data['mobile'] ?? '';
      isHOD = data['isHOD'] == true;
    }

    email = authEmail;
    setState(() => loading = false);
  }

  void _openUpdateDialog() {
    final nameController = TextEditingController(text: name);
    final mobileController = TextEditingController(text: mobile);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Update Profile"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: "Full Name"),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: mobileController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: "Mobile Number"),
            ),
            const SizedBox(height: 12),
            TextField(
              enabled: false,
              decoration: InputDecoration(
                labelText: "Email",
                hintText: email,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              final uid = _auth.currentUser!.uid;

              await _firestore
                  .collection('library_department')
                  .doc(uid)
                  .set({
                'name': nameController.text.trim(),
                'mobile': mobileController.text.trim(),
                'updatedAt': FieldValue.serverTimestamp(),
              }, SetOptions(merge: true));

              setState(() {
                name = nameController.text.trim();
                mobile = mobileController.text.trim();
              });

              Navigator.pop(context);

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Profile updated ✅")),
              );
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  Widget _profileRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.black54,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? '-' : value,
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("My Profile"),
        backgroundColor: Colors.purple,
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _profileRow("Full Name", name),
                  _profileRow("Email", email),
                  _profileRow("Mobile No", mobile),
                  _profileRow(
                    "Role",
                    isHOD ? "Library HOD" : "Library Staff",
                  ),
                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _openUpdateDialog,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple,
                        minimumSize: const Size(double.infinity, 48),
                      ),
                      child: const Text("Update Profile"),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
