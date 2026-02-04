import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// 🔥 UPDATE PROFILE PAGE
import 'alumni_update_profile.dart';

class AlumniProfilePage extends StatelessWidget {
  const AlumniProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(title: const Text("My Profile")),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance
            .collection("alumni_users")
            .doc(uid)
            .get(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snap.hasData || !snap.data!.exists) {
            return const Center(
              child: Text(
                "Profile not found!",
                style: TextStyle(color: Colors.red, fontSize: 18),
              ),
            );
          }

          final data = snap.data!.data() as Map<String, dynamic>;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                /// 🔹 BASIC INFO
                Text(
                  data['name'] ?? '',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),

                Text("Email: ${data['email'] ?? ''}"),
                Text("Mobile: ${data['mobile'] ?? ''}"),
                Text("Batch: ${data['batch'] ?? ''}"),

                const SizedBox(height: 20),
                const Divider(),

                /// 🔹 PROFESSIONAL INFO
                Text("Company: ${data['company'] ?? 'Not updated'}"),
                Text("Position: ${data['position'] ?? 'Not updated'}"),
                Text("Skills: ${data['skills'] ?? 'Not updated'}"),
                Text("LinkedIn: ${data['linkedin'] ?? 'Not updated'}"),

                const SizedBox(height: 20),
                const Divider(),

                /// 🔹 ABOUT SECTION
                const Text(
                  "About",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(data['about'] ?? "Not added"),

                const SizedBox(height: 20),

                /// 🔥 UPDATE PROFILE BUTTON (THIS WAS MISSING)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.edit),
                    label: const Text("Update Profile"),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              AlumniUpdateProfilePage(userId: uid),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
