import 'package:flutter/material.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue[50],
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                "WELCOME TO",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),

              const SizedBox(height: 5),

              const Text(
                "SYNERGY INSTITUTE OF\nENGINEERING AND TECHNOLOGY",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: Colors.black87,
                ),
              ),

              const SizedBox(height: 40),

              buildLoginButton(
                context,
                icon: Icons.school,
                label: "TEACHER LOGIN",
                route: "/teacher_login",
              ),

              buildLoginButton(
                context,
                icon: Icons.person,
                label: "STUDENT LOGIN",
                route: "/student_login",
              ),

              buildLoginButton(
                context,
                icon: Icons.group,
                label: "ALUMNI LOGIN",
                route: "/alumni_login",
              ),

              buildLoginButton(
                context,
                icon: Icons.apartment,
                label: "DEPARTMENT LOGIN",
                route: "/department_login",
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildLoginButton(BuildContext context,
      {required IconData icon, required String label, required String route}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue,
          minimumSize: const Size(double.infinity, 55),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        icon: Icon(icon, color: Colors.white),
        label: Text(
          label,
          style: const TextStyle(
            fontSize: 18,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        onPressed: () => Navigator.pushNamed(context, route),
      ),
    );
  }
}
