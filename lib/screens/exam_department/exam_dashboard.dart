import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

// EXAM PAGES
import 'exam_schedule.dart';
import 'exam_results.dart';
import 'exam_reports.dart';
import 'exam_notices.dart';
import 'exam_profile.dart';
import 'exam_login.dart';

class ExamDashboard extends StatelessWidget {
  const ExamDashboard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Exam Department"),
        backgroundColor: Colors.orange,
        actions: [
          IconButton(
            tooltip: "My Profile",
            icon: const Icon(Icons.person),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const ExamProfilePage(),
                ),
              );
            },
          ),
          IconButton(
            tooltip: "Logout",
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(
                  builder: (_) => const ExamLogin(),
                ),
                (route) => false,
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          children: [
            _dashboardCard(
              icon: Icons.schedule,
              title: "Exam Schedule",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ExamSchedulePage(),
                  ),
                );
              },
            ),
            _dashboardCard(
              icon: Icons.assignment,
              title: "Exam Results",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ExamResultsPage(),
                  ),
                );
              },
            ),
            _dashboardCard(
              icon: Icons.bar_chart,
              title: "Exam Reports",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ExamReportsPage(),
                  ),
                );
              },
            ),
            _dashboardCard(
              icon: Icons.notifications,
              title: "Exam Notices",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ExamNoticesPage(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // ================= DASHBOARD CARD =================
  Widget _dashboardCard({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48, color: Colors.orange),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
