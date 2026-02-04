import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Department HOD Dashboards
import 'accounts_hod/accounts_hod_dashboard.dart';
import 'exam_hod/exam_hod_dashboard.dart';
import 'library_hod/library_hod_dashboard.dart';

// Teacher HOD Dashboard
import '../teacher_hod/hod_dashboard.dart';

// Normal Teacher Dashboard
import '../teacher/teacher_dashboard.dart';

class HODLoginPage extends StatefulWidget {
  const HODLoginPage({super.key});

  @override
  State<HODLoginPage> createState() => _HODLoginPageState();
}

class _HODLoginPageState extends State<HODLoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool loading = false;

  Future<void> loginHOD() async {
    try {
      setState(() => loading = true);

      // LOGIN
      UserCredential userCred =
          await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      String uid = userCred.user!.uid;

      // -----------------------------------------------------------
      // 1) CHECK TEACHERS COLLECTION FIRST (Branch HOD or Teacher)
      // -----------------------------------------------------------
      DocumentSnapshot teacherDoc = await FirebaseFirestore.instance
          .collection("teachers")
          .doc(uid)
          .get();

      if (teacherDoc.exists) {
        final data = teacherDoc.data() as Map<String, dynamic>;
        bool isBranchHOD = data['isBranchHOD'] ?? false;

        if (isBranchHOD) {
          String course = data['course'] ?? "";
          String branch = data['branch'] ?? "";

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => HODDashboard(
                course: course,
                branch: branch,
              ),
            ),
          );
          return;
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => const TeacherDashboard(),
            ),
          );
          return;
        }
      }

      // -----------------------------------------------------------
      // 2) CHECK USERS COLLECTION (Department HOD)
      // -----------------------------------------------------------
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection("users")
          .doc(uid)
          .get();

      if (userDoc.exists) {
        final data = userDoc.data() as Map<String, dynamic>;
        String role = data['role'];
        String department = data['department'];

        if (role == "hod") {
          if (department == "accounts") {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => const AccountsHODDashboard(),
              ),
            );
          } else if (department == "exam") {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => const ExamHODDashboard(),
              ),
            );
          } else if (department == "library") {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => const LibraryHODDashboard(),
              ),
            );
          }
          return;
        }
      }

      throw "Not authorized to login as HOD!";

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Login failed: $e")),
      );
    } finally {
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("HOD Login")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: "Email"),
            ),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(labelText: "Password"),
              obscureText: true,
            ),
            const SizedBox(height: 20),

            loading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: loginHOD,
                    child: const Text("Login"),
                  ),
          ],
        ),
      ),
    );
  }
}
