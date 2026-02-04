import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'student_update_profile.dart';

class StudentProfileViewPage extends StatefulWidget {
  const StudentProfileViewPage({super.key});

  @override
  State<StudentProfileViewPage> createState() => _StudentProfileViewPageState();
}

class _StudentProfileViewPageState extends State<StudentProfileViewPage> {
  Map<String, dynamic>? studentData;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final doc = await FirebaseFirestore.instance.collection('students').doc(user.uid).get();
    setState(() => studentData = doc.data());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Student Profile")),
      body: studentData == null
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: ListView(
                children: [
                  Text("Name: ${studentData!['name']}"),
                  Text("Roll No: ${studentData!['rollNo']}"),
                  Text("Email: ${studentData!['email']}"),
                  Text("Mobile: ${studentData!['mobile']}"),
                  Text("Parent Name: ${studentData!['parentName'] ?? '-'}"),
                  Text("Parent No: ${studentData!['parentMobile'] ?? '-'}"),
                  Text("Address: ${studentData!['address'] ?? '-'}"),
                  Text("Blood Group: ${studentData!['bloodGroup'] ?? '-'}"),
                  Text("DOB: ${studentData!['dob'] ?? '-'}"),
                  Text("Course: ${studentData!['course'] ?? '-'}"),
                  const SizedBox(height: 20),
                  ElevatedButton(
                      onPressed: () {
                        Navigator.pushReplacement(context,
                            MaterialPageRoute(builder: (_) => const StudentUpdateProfilePage()));
                      },
                      child: const Text("Update Profile")),
                ],
              ),
            ),
    );
  }
}
