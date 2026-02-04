import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';

class AlumniPostJobPage extends StatefulWidget {
  final String? jobId;
  final Map<String, dynamic>? existingData;

  const AlumniPostJobPage({
    super.key,
    this.jobId,
    this.existingData,
  });

  @override
  State<AlumniPostJobPage> createState() => _AlumniPostJobPageState();
}

class _AlumniPostJobPageState extends State<AlumniPostJobPage> {
  final title = TextEditingController();
  final company = TextEditingController();
  final location = TextEditingController();
  final salary = TextEditingController();
  final desc = TextEditingController();
  final skills = TextEditingController();
  final experience = TextEditingController();
  final applyLink = TextEditingController();

  Uint8List? selectedImage;
  bool loading = false;

  @override
  void initState() {
    super.initState();
    if (widget.existingData != null) {
      title.text = widget.existingData!['title'] ?? '';
      company.text = widget.existingData!['company'] ?? '';
      location.text = widget.existingData!['location'] ?? '';
      salary.text = widget.existingData!['salary'] ?? '';
      skills.text = widget.existingData!['skillsRequired'] ?? '';
      experience.text = widget.existingData!['experience'] ?? '';
      applyLink.text = widget.existingData!['applyLink'] ?? '';
      desc.text = widget.existingData!['description'] ?? '';

      final base64 = widget.existingData!['imageBase64'];
      if (base64 != null && base64.toString().isNotEmpty) {
        selectedImage = base64Decode(base64);
      }
    }
  }

  Future<void> pickImage() async {
    final img = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (img == null) return;
    selectedImage = await img.readAsBytes();
    setState(() {});
  }

  // 🔥 POST JOB (FIXED VERSION)
  Future<void> postJob() async {
    setState(() => loading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw "User not logged in";

      final uid = user.uid;

      // 1. Fetch Alumni Profile (To get Name & Chat ID)
      final userDoc = await FirebaseFirestore.instance.collection("alumni_users").doc(uid).get();
      if (!userDoc.exists) throw "Alumni profile not found";

      final alumniName = userDoc.data()?["name"] ?? "Alumni";
      final alumniChatifyId = userDoc.data()?["chatifyUserId"] ?? "";

      // 2. Prepare Image
      String? base64Image;
      if (selectedImage != null) {
        base64Image = base64Encode(selectedImage!);
      }

      // 3. Prepare Data (🔥 CORRECT FORMAT FIXED HERE)
      // 'postedBy' must be UID (String) so Job Feed can find the user.
      final data = {
        "title": title.text.trim(),
        "company": company.text.trim(),
        "location": location.text.trim(),
        "salary": salary.text.trim(),
        "skillsRequired": skills.text.trim(),
        "experience": experience.text.trim(),
        "applyLink": applyLink.text.trim(),
        "description": desc.text.trim(),
        "imageBase64": base64Image,
        
        // ✅ CORRECT: Saving UID as String
        "postedBy": uid, 
        // ✅ Saving Name separately for display
        "postedByName": alumniName,
        // ✅ Saving Chat ID for backup
        "posterChatId": alumniChatifyId, 

        "postedAt": FieldValue.serverTimestamp(),
      };

      // 4. Save to Firestore
      if (widget.jobId == null) {
        await FirebaseFirestore.instance.collection("jobs").add(data);
      } else {
        await FirebaseFirestore.instance.collection("jobs").doc(widget.jobId).update(data);
      }

      if (mounted) Navigator.pop(context);

    } catch (e) {
      print("Error posting job: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.jobId != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? "Edit Job" : "Post Job"),
        backgroundColor: Colors.indigo, // Alumni Theme
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          TextField(controller: title, decoration: const InputDecoration(labelText: "Job Title", border: OutlineInputBorder())),
          const SizedBox(height: 10),
          TextField(controller: company, decoration: const InputDecoration(labelText: "Company", border: OutlineInputBorder())),
          const SizedBox(height: 10),
          TextField(controller: location, decoration: const InputDecoration(labelText: "Location", border: OutlineInputBorder())),
          const SizedBox(height: 10),
          TextField(controller: salary, decoration: const InputDecoration(labelText: "Salary", border: OutlineInputBorder())),
          const SizedBox(height: 10),
          TextField(controller: skills, decoration: const InputDecoration(labelText: "Skills Required", border: OutlineInputBorder())),
          const SizedBox(height: 10),
          TextField(controller: experience, decoration: const InputDecoration(labelText: "Experience", border: OutlineInputBorder())),
          const SizedBox(height: 10),
          TextField(controller: applyLink, decoration: const InputDecoration(labelText: "Apply Link", border: OutlineInputBorder())),
          const SizedBox(height: 10),
          TextField(controller: desc, maxLines: 3, decoration: const InputDecoration(labelText: "Description", border: OutlineInputBorder())),
          const SizedBox(height: 15),
          
          ElevatedButton.icon(
            onPressed: pickImage, 
            icon: const Icon(Icons.image),
            label: const Text("Upload Image"),
          ),
          
          if (selectedImage != null)
            Padding(padding: const EdgeInsets.only(top: 10), child: Image.memory(selectedImage!, height: 150)),
          
          const SizedBox(height: 20),
          
          SizedBox(
            height: 50,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, foregroundColor: Colors.white),
              onPressed: loading ? null : postJob,
              child: loading ? const CircularProgressIndicator(color: Colors.white) : Text(isEdit ? "Update Job" : "Post Job", style: const TextStyle(fontSize: 18)),
            ),
          ),
        ],
      ),
    );
  }
}