import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../widgets/common_textfield.dart';
import 'library_dashboard.dart';
import 'library_register.dart';

class LibraryLogin extends StatefulWidget {
  const LibraryLogin({Key? key}) : super(key: key);

  @override
  State<LibraryLogin> createState() => _LibraryLoginState();
}

class _LibraryLoginState extends State<LibraryLogin> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool loading = false;

  Future<void> login() async {
    setState(() => loading = true);
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _email.text.trim(),
        password: _password.text.trim(),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LibraryDashboard()),
      );
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.purple[50],
      body: Center(
        child: Card(
          elevation: 8,
          margin: const EdgeInsets.all(24),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "Library Login",
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                CommonTextField(controller: _email, label: "Email"),
                const SizedBox(height: 12),
                CommonTextField(
                  controller: _password,
                  label: "Password",
                  isPassword: true,
                ),
                const SizedBox(height: 20),
                loading
                    ? const CircularProgressIndicator()
                    : ElevatedButton(
                        onPressed: login,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.purple,
                          minimumSize: const Size(double.infinity, 45),
                        ),
                        child: const Text("Login"),
                      ),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const LibraryRegisterPage()),
                    );
                  },
                  child: const Text("Create account"),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
