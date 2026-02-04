import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

// 🟦 HOD FEATURES IMPORTS
import 'hod_notice_page.dart';
import 'hod_routine_manager.dart';
import 'hod_attendance_page.dart';
import 'hod_view_students.dart';

class HODDashboard extends StatelessWidget {
  final String course;
  final String branch;

  const HODDashboard({
    super.key,
    required this.course,
    required this.branch,
  });

  // 🔹 Reusable Dashboard Card
  Widget dashboardCard({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Card(
        elevation: 4,
        color: Colors.blue[50],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 42, color: Colors.blue),
              const SizedBox(height: 8),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              )
            ],
          ),
        ),
      ),
    );
  }

  // 🔹 Logout
  Future<void> _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushNamedAndRemoveUntil(
      context,
      '/teacher_login',
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue[50],

      appBar: AppBar(
        title: Text("HOD Dashboard ($branch)"),
        backgroundColor: Colors.blue,
        actions: [
          IconButton(
            onPressed: () => _logout(context),
            icon: const Icon(Icons.logout),
            tooltip: "Logout",
          )
        ],
      ),

      body: Padding(
        padding: const EdgeInsets.all(16),
        child: GridView.count(
          crossAxisCount: 2,
          childAspectRatio: 1.1,
          crossAxisSpacing: 20,
          mainAxisSpacing: 20,
          children: [

            // NOTICE
            dashboardCard(
              icon: Icons.notifications_active,
              label: "Upload Notice",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        HODNoticePage(course: course, branch: branch),
                  ),
                );
              },
            ),

            // ROUTINE MANAGER
            dashboardCard(
              icon: Icons.schedule,
              label: "Routine Manager",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        HODRoutineManager(course: course, branch: branch),
                  ),
                );
              },
            ),

            // ATTENDANCE
            dashboardCard(
              icon: Icons.check_circle,
              label: "Branch Attendance",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        HODAttendancePage(course: course, branch: branch),
                  ),
                );
              },
            ),

            // VIEW STUDENTS
            dashboardCard(
              icon: Icons.group,
              label: "View Students",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        HODViewStudentsPage(course: course, branch: branch),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
