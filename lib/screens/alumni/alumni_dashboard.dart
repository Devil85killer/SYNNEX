import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../services/socket_service.dart';
import '../../main.dart'; // ✅ IMPORTED for 'socket' and 'connectSocket'

// ALUMNI PAGES
import 'alumni_profile.dart';
import 'alumni_post_job.dart';
import 'alumni_my_jobs.dart';
import 'alumni_chat_list.dart';

// ✅ COMMON JOB FEED
import 'package:synnex/screens/jobs/common_job_feed_page.dart';

class AlumniDashboard extends StatefulWidget {
  const AlumniDashboard({super.key});

  @override
  State<AlumniDashboard> createState() => _AlumniDashboardState();
}

class _AlumniDashboardState extends State<AlumniDashboard> {
  int _index = 0;

  /// ✅ PAGES
  final List<Widget> _pages = const [
    AlumniHomePage(),
    AlumniProfilePage(),
    AlumniPostJobPage(),
    AlumniMyJobsPage(),
    CommonJobFeedPage(),
    AlumniChatListPage(),
  ];

  final List<String> _titles = [
    "Dashboard",
    "Profile",
    "Post Job",
    "My Job Posts",
    "Job Feed",
    "Chats",
  ];

  @override
  void initState() {
    super.initState();
    // 🔥 SMART CHECK: Check if socket needs reconnection after a refresh
    _checkSocket();
  }

  /// 🔌 SMART RECONNECT FOR ALUMNI
  Future<void> _checkSocket() async {
    // 1. Agar socket already connected hai toh return
    if (socket != null && socket!.connected) {
      print("✅ Alumni Dashboard: Socket already active");
      return;
    }

    print("🔄 Alumni Dashboard: Refresh detected. Reconnecting Socket...");
    
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;

      // 2. Alumni ka JWT aur MongoID Firestore se fetch karo
      final userDoc = await FirebaseFirestore.instance
          .collection('alumni_users')
          .doc(uid)
          .get();

      if (userDoc.exists) {
        final data = userDoc.data();
        if (data != null) {
          final jwt = data['chatifyJwt'];
          final myMongoId = data['chatifyUserId']; // ✅ FIX: MongoID nikala

          // ✅ FIX: Ab Token aur ID dono bhej rahe hain
          if (jwt != null && myMongoId != null) {
            connectSocket(jwt, myMongoId); // 👈 FIXED: 2 Arguments Passed
            print("🚀 Alumni Dashboard: Reconnection initiated for ID: $myMongoId");
          }
        }
      }
    } catch (e) {
      print("❌ Alumni Dashboard Reconnect Error: $e");
    }
  }

  /// 🚪 LOGOUT (SOCKET + FIREBASE)
  Future<void> _logout() async {
    // Sirf listeners clean karo
    SocketService().disconnect(); 
    
    await FirebaseAuth.instance.signOut();

    if (mounted) {
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/alumni_login',
        (_) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_index]),
        backgroundColor: Colors.blue,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: "Logout",
            onPressed: _logout,
          ),
        ],
      ),
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: _index,
            onDestinationSelected: (i) {
              setState(() => _index = i);
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
                icon: Icon(Icons.post_add),
                label: Text("Post Job"),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.work),
                label: Text("My Job Posts"),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.public),
                label: Text("Job Feed"),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.chat),
                label: Text("Chats"),
              ),
            ],
          ),
          const VerticalDivider(width: 1),
          Expanded(
            child: Container(
              color: Colors.grey.shade100,
              child: _pages[_index],
            ),
          ),
        ],
      ),
    );
  }
}

//////////////////// HOME PAGE ////////////////////

class AlumniHomePage extends StatelessWidget {
  const AlumniHomePage({super.key});

  String greet() {
    final h = DateTime.now().hour;
    if (h < 12) return "Good Morning";
    if (h < 17) return "Good Afternoon";
    return "Good Evening";
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            "${greet()}, Alumni 👋",
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          const Icon(Icons.work_outline, size: 120),
        ],
      ),
    );
  }
}