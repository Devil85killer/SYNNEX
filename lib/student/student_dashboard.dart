import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/socket_service.dart'; 
import '../../main.dart'; // Global socket access

// STUDENT PAGES
import 'student_routine.dart';
import 'student_profile_view.dart';
import 'student_attendance.dart';
import 'student_fees.dart';
import 'student_books.dart';
import 'student_exam_reports.dart';
import 'student_complaints.dart';
import 'student_chat_list.dart';

// COMMON JOB FEED
import '../screens/jobs/common_job_feed_page.dart';

class StudentDashboard extends StatefulWidget {
  const StudentDashboard({super.key});

  @override
  State<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard> {
  int _selectedIndex = 0;

  final List<Widget> _pages = const [
    StudentHomePage(),
    StudentProfileViewPage(),
    StudentAttendancePage(),
    StudentFeesPage(),
    StudentBooksPage(),
    StudentExamReportsPage(),
    StudentComplaintsPage(),
    CommonJobFeedPage(),
    StudentChatListPage(),
  ];

  final List<String> _titles = [
    "Dashboard",
    "Profile",
    "Attendance",
    "Fees",
    "Books",
    "Exam Reports",
    "Complaints",
    "Jobs",
    "Chats",
  ];

  @override
  void initState() {
    super.initState();
    // Dashboard load hote hi socket connect aur user ko online dikhao
    _checkSocket();
  }

  /// 🔌 SMART RECONNECT & ONLINE STATUS (FCM + SETUP)
  Future<void> _checkSocket() async {
    print("🔄 Student Dashboard: Initializing Online Status...");
    
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;

      final userDoc = await FirebaseFirestore.instance
          .collection('students')
          .doc(uid)
          .get();

      if (userDoc.exists) {
        final data = userDoc.data();
        if (data != null) {
          final jwt = data['chatifyJwt'];
          final myMongoId = data['chatifyUserId'];

          if (jwt != null && myMongoId != null) {
            // 1. Connection logic initiate karo
            connectSocket(jwt, myMongoId); 
            
            // 2. 🔥 FORCE SETUP (Wait until socket connects then emit)
            // Isse server ko pata chal jayega ki aap kis socket ID pe online ho
            if (socket != null) {
               if (socket!.connected) {
                  socket!.emit("setup", myMongoId);
                  print("🚀 Setup Sent: User $myMongoId is now LIVE");
               } else {
                  socket!.on('connect', (_) {
                    socket!.emit("setup", myMongoId);
                    print("🚀 Connected & Setup Sent: User $myMongoId is now LIVE");
                  });
               }
            }
          }
        }
      }
    } catch (e) {
      print("❌ Student Dashboard Reconnect Error: $e");
    }
  }

  /// 🚪 LOGOUT
  Future<void> _logout() async {
    SocketService().disconnect(); 
    await FirebaseAuth.instance.signOut();

    if (mounted) {
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/student_login',
        (_) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_selectedIndex]),
        backgroundColor: Colors.blue,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      body: Row(
        children: [
          /// 1. LEFT MENU (NavigationRail)
          NavigationRail(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (i) {
              setState(() => _selectedIndex = i);
            },
            labelType: NavigationRailLabelType.all,
            destinations: const [
              NavigationRailDestination(
                icon: Icon(Icons.dashboard),
                label: Text("Dashboard"),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.person),
                label: Text("Profile"),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.calendar_today),
                label: Text("Attendance"),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.payment),
                label: Text("Fees"),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.book),
                label: Text("Books"),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.assessment),
                label: Text("Exams"),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.report),
                label: Text("Complaints"),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.work),
                label: Text("Jobs"),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.chat),
                label: Text("Chats"),
              ),
            ],
          ),

          /// 2. DIVIDER
          const VerticalDivider(thickness: 1, width: 1),

          /// 3. MAIN CONTENT
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

////////////////////////////////////////////////////////////
/// HOME PAGE (DASHBOARD TAB)
////////////////////////////////////////////////////////////

class StudentHomePage extends StatelessWidget {
  const StudentHomePage({super.key});

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
            "${greet()}, Student 👋",
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.blueAccent,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            "Explore jobs, chat with alumni & stay updated.",
            style: TextStyle(fontSize: 16),
          ),
        ],
      ),
    );
  }
}