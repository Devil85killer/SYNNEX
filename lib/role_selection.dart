import 'package:flutter/material.dart';

class RoleSelectionPage extends StatelessWidget {
  const RoleSelectionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue.shade50,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(30),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                "Select Your Role",
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 40),

              roleButton(
                context,
                title: "Teacher Login",
                color: Colors.blue,
                route: '/teacher_login',
              ),

              const SizedBox(height: 20),

              roleButton(
                context,
                title: "Student Login",
                color: Colors.green,
                route: '/student_login',
              ),

              const SizedBox(height: 20),

              roleButton(
                context,
                title: "Alumni Login",
                color: Colors.purple,
                route: '/alumni_login',
              ),

              const SizedBox(height: 20),

              roleButton(
                context,
                title: "Department Login",
                color: Colors.orange,
                route: '/department_login',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget roleButton(BuildContext context,
      {required String title, required Color color, required String route}) {
    return SizedBox(
      width: 260,
      height: 55,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onPressed: () => Navigator.pushNamed(context, route),
        child: Text(
          title,
          style: const TextStyle(fontSize: 20, color: Colors.white),
        ),
      ),
    );
  }
}

