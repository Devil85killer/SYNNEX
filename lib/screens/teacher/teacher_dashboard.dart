import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../services/socket_service.dart';
import '../../main.dart'; // ✅ Global 'socket' and 'connectSocket' access

// TEACHER PAGES
import 'teacher_books.dart';
import 'teacher_routine.dart';
import 'teacher_attendance.dart';
import 'teacher_profile.dart';

// ✅ COMMON JOB FEED
import 'package:synnex/screens/jobs/common_job_feed_page.dart';

// HOD PAGES
import '../teacher_hod/hod_students_page.dart';
import '../teacher_hod/hod_notice_page.dart';
import '../teacher_hod/hod_routine_manager.dart';
import '../teacher_hod/hod_attendance_page.dart';

// CHAT LIST
import 'teacher_chat/teacher_chat_list.dart';

class TeacherDashboard extends StatefulWidget {
  const TeacherDashboard({Key? key}) : super(key: key);

  @override
  State<TeacherDashboard> createState() => _TeacherDashboardState();
}

class _TeacherDashboardState extends State<TeacherDashboard> {
  
  @override
  void initState() {
    super.initState();
    // 🔥 Dashboard load hote hi socket check aur setup karo
    _checkSocket(); 
  }

  /// 🔌 SMART RECONNECT & ONLINE STATUS SETUP
  Future<void> _checkSocket() async {
    print("🔄 Teacher Dashboard: Syncing Socket Status...");
    
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;

      // 1. Fetch Teacher's JWT & MongoID from Firestore
      final userDoc = await FirebaseFirestore.instance
          .collection('teachers')
          .doc(uid)
          .get();

      if (userDoc.exists) {
        final data = userDoc.data();
        if (data != null) {
          final jwt = data['chatifyJwt'];
          final myMongoId = data['chatifyUserId'];

          if (jwt != null && myMongoId != null) {
            // 2. Connection initiate karo
            connectSocket(jwt, myMongoId); 
            
            // 3. 🔥 FORCE SETUP: Ensure server knows we are online
            if (socket != null) {
               if (socket!.connected) {
                  // Agar socket pehle se connected hai toh turant setup bhej do
                  socket!.emit("setup", myMongoId);
                  print("🚀 Teacher Online Setup Sent: $myMongoId");
               } else {
                  // Agar abhi connect ho raha hai, toh connection bante hi setup bhej do
                  socket!.on('connect', (_) {
                    socket!.emit("setup", myMongoId);
                    print("🚀 Teacher Handshake Complete: $myMongoId");
                  });
               }
            }
          }
        }
      }
    } catch (e) {
      print("❌ Teacher Dashboard Reconnect Error: $e");
    }
  }

  /// 🚪 LOGOUT
  Future<void> _logout() async {
    SocketService().disconnect(); 
    await FirebaseAuth.instance.signOut();

    if (mounted) {
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/teacher_login',
        (_) => false,
      );
    }
  }

  Widget buildCard({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Card(
        color: Colors.blue[50],
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.blue, size: 40),
              const SizedBox(height: 10),
              Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      backgroundColor: Colors.blue[50],
      appBar: AppBar(
        title: const Text("Teacher Dashboard"),
        backgroundColor: Colors.blue,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('teachers')
            .doc(uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.blue),
            );
          }

          final data = snapshot.data!.data() as Map<String, dynamic>? ?? {};
          final bool isHOD = data['isBranchHOD'] == true;
          final String course = data['course'] ?? "";
          final String branch = data['branch'] ?? "";

          return Padding(
            padding: const EdgeInsets.all(16),
            child: GridView.count(
              crossAxisCount: 2,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              children: [
                buildCard(
                  icon: Icons.menu_book,
                  label: "Books",
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const TeacherBooksPage()),
                  ),
                ),
                buildCard(
                  icon: Icons.schedule,
                  label: "Routine",
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const TeacherRoutinePage()),
                  ),
                ),
                buildCard(
                  icon: Icons.calendar_today,
                  label: "Attendance",
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => TeacherAttendancePage(),
                      settings: RouteSettings(
                        arguments: {"course": course, "branch": branch},
                      ),
                    ),
                  ),
                ),
                buildCard(
                  icon: Icons.person,
                  label: "Profile",
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const TeacherProfilePage()),
                  ),
                ),
                buildCard(
                  icon: Icons.chat_bubble,
                  label: "Chats",
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const TeacherChatListPage()),
                  ),
                ),
                buildCard(
                  icon: Icons.work,
                  label: "Job Feed",
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const CommonJobFeedPage()),
                  ),
                ),
                if (isHOD) ...[
                  buildCard(
                    icon: Icons.group,
                    label: "Branch Students",
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => HODStudentsPage(course: course, branch: branch),
                      ),
                    ),
                  ),
                  buildCard(
                    icon: Icons.notifications,
                    label: "Upload Notice",
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => HODNoticePage(course: course, branch: branch),
                      ),
                    ),
                  ),
                  buildCard(
                    icon: Icons.edit_calendar,
                    label: "Manage Routine",
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => HODRoutineManager(course: course, branch: branch),
                      ),
                    ),
                  ),
                  buildCard(
                    icon: Icons.fact_check,
                    label: "Class Attendance",
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => HODAttendancePage(course: course, branch: branch),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}