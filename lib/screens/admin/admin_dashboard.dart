import 'package:flutter/material.dart';

// ADMIN MODULES (EXISTING)
import 'manage_courses/manage_courses.dart';
import 'manage_departments/manage_departments.dart';
import 'admin_all_alumni.dart';
import 'admin_call_logs.dart';
import 'attendance_management.dart';
import 'complaints.dart';
import 'routine_management.dart';
import 'logout_page.dart';
import 'student_approval.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({Key? key}) : super(key: key);

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _selectedIndex = 0;

  // ================= PAGES =================
  final List<Widget> _pages = const [
    AdminHomePage(),          // 0
    ManageCourses(),          // 1
    ManageDepartments(),      // 2
    AdminAllAlumniPage(),     // 3
    AdminCallLogsPage(),      // 4
    AttendanceManagement(),   // 5
    Complaints(),             // 6
    RoutineManagement(),      // 7
    LogoutPage(),             // 8
    StudentApproval(),    // 9 ✅ ADDED
  ];

  // ================= TITLES =================
  final List<String> _titles = const [
    "Admin Dashboard",
    "Academics",
    "Departments",
    "All Alumni",
    "CL Logs",
    "Attendance",
    "Complaints",
    "Routine Management",
    "Logout",
    "Student Approval", // ✅ ADDED
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_selectedIndex]),
        backgroundColor: Colors.blueAccent,
      ),
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: _selectedIndex,
            labelType: NavigationRailLabelType.all,
            onDestinationSelected: (index) {
              setState(() => _selectedIndex = index);
            },
            destinations: const [
              NavigationRailDestination(
                icon: Icon(Icons.dashboard),
                label: Text("Dashboard"),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.school),
                label: Text("Academics"),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.apartment),
                label: Text("Departments"),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.people),
                label: Text("All Alumni"),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.call),
                label: Text("CL Logs"),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.how_to_reg),
                label: Text("Attendance"),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.report),
                label: Text("Complaints"),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.calendar_today),
                label: Text("Routine"),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.logout),
                label: Text("Logout"),
              ),
              // ✅ LAST DESTINATION
              NavigationRailDestination(
                icon: Icon(Icons.verified_user),
                label: Text("Student Approval"),
              ),
            ],
          ),
          Expanded(
            child: Container(
              color: Colors.grey.shade100,
              child: _pages[_selectedIndex],
            ),
          ),
        ],
      ),
    );
  }
}

// ===================================================
// ================= ADMIN HOME =======================
// ===================================================

class AdminHomePage extends StatelessWidget {
  const AdminHomePage({Key? key}) : super(key: key);

  String greet() {
    final h = DateTime.now().hour;
    if (h < 12) return "Good Morning";
    if (h < 17) return "Good Afternoon";
    return "Good Evening";
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "${greet()}, Admin 👋",
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.blueAccent,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            "College ERP – Admin Control Panel",
            style: TextStyle(color: Colors.black54),
          ),
          const SizedBox(height: 30),
          Expanded(
            child: Center(
              child: Icon(
                Icons.admin_panel_settings,
                size: 140,
                color: Colors.blueAccent.withOpacity(0.3),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
