import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../widgets/common_textfield.dart';

class LibraryUpdateProfilePage extends StatefulWidget {
  const LibraryUpdateProfilePage({Key? key}) : super(key: key);

  @override
  State<LibraryUpdateProfilePage> createState() => _LibraryUpdateProfilePageState();
}

class _LibraryUpdateProfilePageState extends State<LibraryUpdateProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _name = TextEditingController();
  final TextEditingController _dob = TextEditingController();
  final TextEditingController _bloodGroup = TextEditingController();
  bool _loading = false;

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    final uid = FirebaseAuth.instance.currentUser?.uid;
    try {
      await FirebaseFirestore.instance.collection('library_department').doc(uid).set({
        'name': _name.text.trim(),
        'dob': _dob.text.trim(),
        'bloodGroup': _bloodGroup.text.trim(),
        'profileCompleted': true,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Profile updated successfully!')));
      Navigator.pushReplacementNamed(context, '/library_dashboard');
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error updating profile: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Library - Update Profile'),
        backgroundColor: Colors.purple,
      ),
      backgroundColor: Colors.purple[50],
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              Text('Email: ${user?.email ?? ''}', style: const TextStyle(fontSize: 16)),
              const SizedBox(height: 16),
              CommonTextField(controller: _name, label: 'Full Name'),
              const SizedBox(height: 12),
              CommonTextField(controller: _dob, label: 'Date of Birth (DD/MM/YYYY)'),
              const SizedBox(height: 12),
              CommonTextField(controller: _bloodGroup, label: 'Blood Group'),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _loading ? null : _updateProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: _loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Save Profile'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
