import 'package:flutter/material.dart';

// 🧭 Import all student pages
import 'student_dashboard.dart';
import 'student_profile_view.dart';
import 'student_attendance.dart';
import 'student_fees.dart';
import 'student_books.dart';
import 'student_complaints.dart';
import 'student_exam_reports.dart';
import 'student_job_feed.dart';   // 🔥 NEW IMPORT

class StudentSideMenu extends StatelessWidget {
  final Function(Widget) onPageSelected;

  const StudentSideMenu({super.key, required this.onPageSelected});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF004AAD), Color(0xFF00B4DB)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: ListView(
        padding: const EdgeInsets.symmetric(vertical: 20),
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              "Student Panel",
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const Divider(color: Colors.white54),

          _menuItem(Icons.dashboard, "Dashboard", const DashboardHomePage()),
          _menuItem(Icons.person, "Profile", const StudentProfileViewPage()),
          _menuItem(Icons.calendar_month, "Attendance", const StudentAttendancePage()),
          _menuItem(Icons.payment, "Fees", const StudentFeesPage()),
          _menuItem(Icons.book, "Books", const StudentBooksPage()),
          _menuItem(Icons.report, "Exam Reports", const StudentExamReportsPage()),
          _menuItem(Icons.chat_bubble, "Complaints", const StudentComplaintsPage()),

          // 🔥 NEW – JOB FEED BUTTON
          _menuItem(Icons.work, "Job Feed", const StudentJobFeedPage()),

          const SizedBox(height: 20),
          const Divider(color: Colors.white54),

          _logoutButton(context),
        ],
      ),
    );
  }

  Widget _menuItem(IconData icon, String title, Widget page) {
    return InkWell(
      onTap: () => onPageSelected(page),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 22),
            const SizedBox(width: 12),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _logoutButton(BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
      },
      child: const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(Icons.logout, color: Colors.white),
            SizedBox(width: 10),
            Text(
              "Logout",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
