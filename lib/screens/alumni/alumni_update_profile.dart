import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Correct dashboard class
import 'alumni_dashboard.dart';

class AlumniUpdateProfilePage extends StatefulWidget {
  final String userId;
  const AlumniUpdateProfilePage({super.key, required this.userId});

  @override
  State<AlumniUpdateProfilePage> createState() => _AlumniUpdateProfilePageState();
}

class _AlumniUpdateProfilePageState extends State<AlumniUpdateProfilePage> {
  final _aboutController = TextEditingController();
  final _skillsController = TextEditingController();
  final _companyController = TextEditingController();
  final _positionController = TextEditingController();
  final _linkedinController = TextEditingController();

  bool _isLoading = false;
  String? _error;
  String? _profilePhotoUrl;

  @override
  void initState() {
    super.initState();
    _loadExisting();
  }

  Future<void> _loadExisting() async {
    final doc = await FirebaseFirestore.instance
        .collection('alumni_users')
        .doc(widget.userId)
        .get();

    if (doc.exists) {
      final data = doc.data()!;
      setState(() {
        _aboutController.text = data['about'] ?? '';
        _skillsController.text = data['skills'] ?? '';
        _companyController.text = data['company'] ?? '';
        _positionController.text = data['position'] ?? '';
        _linkedinController.text = data['linkedin'] ?? '';
        _profilePhotoUrl = data['profilePhoto'];
      });
    }
  }

  Future<void> _saveProfile() async {
    if (_aboutController.text.trim().isEmpty &&
        _skillsController.text.trim().isEmpty) {
      setState(() => _error = "Please enter at least About or Skills.");
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await FirebaseFirestore.instance
          .collection('alumni_users')
          .doc(widget.userId)
          .set({
        'about': _aboutController.text.trim(),
        'skills': _skillsController.text.trim(),
        'company': _companyController.text.trim(),
        'position': _positionController.text.trim(),
        'linkedin': _linkedinController.text.trim(),
        'profilePhoto': _profilePhotoUrl ?? FieldValue.delete(),
        'profileCompleted': true,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (!mounted) return;

      // FIXED: Correct dashboard class
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const AlumniDashboard(),
        ),
      );
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _aboutController.dispose();
    _skillsController.dispose();
    _companyController.dispose();
    _positionController.dispose();
    _linkedinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Complete Your Profile"),
        backgroundColor: Colors.blueAccent,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const SizedBox(height: 8),

                  // Profile photo preview
                  CircleAvatar(
                    radius: 44,
                    backgroundColor: Colors.blue.shade100,
                    backgroundImage: _profilePhotoUrl != null
                        ? NetworkImage(_profilePhotoUrl!)
                        : null,
                    child: _profilePhotoUrl == null
                        ? const Icon(Icons.person, size: 44, color: Colors.white)
                        : null,
                  ),

                  const SizedBox(height: 16),

                  TextField(
                    controller: _aboutController,
                    decoration: const InputDecoration(
                      labelText: "About",
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 12),

                  TextField(
                    controller: _skillsController,
                    decoration: const InputDecoration(
                      labelText: "Skills",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),

                  TextField(
                    controller: _companyController,
                    decoration: const InputDecoration(
                      labelText: "Current Company",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),

                  TextField(
                    controller: _positionController,
                    decoration: const InputDecoration(
                      labelText: "Position",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),

                  TextField(
                    controller: _linkedinController,
                    decoration: const InputDecoration(
                      labelText: "LinkedIn URL",
                      border: OutlineInputBorder(),
                    ),
                  ),

                  const SizedBox(height: 12),

                  if (_error != null)
                    Text(_error!, style: const TextStyle(color: Colors.red)),

                  const SizedBox(height: 12),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _saveProfile,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 48),
                      ),
                      child: const Text("Save & Continue"),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
